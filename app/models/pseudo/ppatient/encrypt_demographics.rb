module Pseudo
  class Ppatient
    # Contains the logic for encrypting / matching / decrypting demographics
    module EncryptDemographics
      # Workaround prescription import script that didn't populate prescription_keyid
      FIXUP_PRESCRIPTION_NULL_KEYID = false

      def self.included(base)
        base.extend(ClassMethods)
      end

      # Class methods for building / matching Ppatient records from demographics
      module ClassMethods
        # Create a Ppatient record based on the given demographics.
        # Parameter demographics is expected to be a hash, with common key names
        # 'nhsnumber', 'postcode' (current, if possible), 'birthdate'
        def initialize_from_demographics(key, demographics, rawtext, fields_no_demog)
          raise('TODO: Not yet implemented') if rawtext
          nhsnumber = demographics['nhsnumber'] || ''
          postcode = demographics['postcode'] || ''
          birthdate = demographics['birthdate'] || ''
          rawdata = find_or_initialize_ppatient_rawdata(key, nhsnumber, postcode,
                                                        birthdate, demographics)
          pseudo_ids = keystore.pseudo_ids([key], nhsnumber, postcode, birthdate, :create)[0]
          pseudonymisation_key = PseudonymisationKey.find_by(key_name: key)
          new(fields_no_demog.merge(pseudonymisation_key: pseudonymisation_key,
                                    pseudo_id1: pseudo_ids[1],
                                    pseudo_id2: pseudo_ids[2],
                                    ppatient_rawdata: rawdata))
        end

        # rubocop:disable Metrics/ParameterLists # Lightweight API for fast lookups
        def find_or_initialize_ppatient_rawdata(key, nhsnumber, postcode, birthdate,
                                                demographics, _pseudo_ids = nil)
          # TODO: Matches patient with blank nhsnumber / postcode / birthdate
          # Only unpack up to 10, to limit cost where the same record occurs many times
          ppats = find_matching_ppatients(nhsnumber, postcode, birthdate, [key], limit: 10)
          ppats.each do |ppat|
            next unless ppat.unlock_demographics(nhsnumber, postcode, birthdate, :create) &&
                        ppat.demographics == demographics
            return ppat.ppatient_rawdata
          end
          demog_json = demographics.to_json
          _pseudo_id1, _pseudo_id2, decrypt_key, rawdata = \
            keystore.encrypt_record(key, :demographics, demog_json, nhsnumber, postcode, birthdate,
                                    :create)
          PpatientRawdata.new(decrypt_key: decrypt_key, rawdata: rawdata)
        end
        # rubocop:enable Metrics/ParameterLists

        # Find ppatients with the same (or similar) demographics to this patient.
        # Optional parameter keys is a list of relevant decryption key names.
        # If building a single patient, this would typically be the current key for that data source
        # If finding a patient, this can be all relevant keys, or nil to use all keys.
        # params: Allowed (optional) keys:
        # :e_types => list of e_types (defaults to nil => allow anything)
        # :match_blank => if true then don't ignore blank nhsnumber / postcode / birthdate parameter
        #                 (defaults to false)
        # :limit => limit number of potentially matching records to return (e.g. when reusing
        #           demographics)
        # :scope => limit Ppatient scope
        def find_matching_ppatients(nhsnumber, postcode, birthdate,
                                    keys = nil, params = {})
          keys ||= Pseudo::PseudonymisationKey.pluck(:key_name)
          # List of triples [key, pseudo_id1, pseudo_id2]
          pseudo_ids_list = keystore.pseudo_ids(keys, nhsnumber, postcode, birthdate, :match)
          sql = ['1 = 0'] # Allow case where no pseudo_id1 / pseudo_id2 values
          values = []
          if params[:match_blank] || nhsnumber&.present?
            sql << 'pseudo_id1 in (?)'
            values << pseudo_ids_list.collect(&:second).compact
          end
          if params[:match_blank] || (postcode&.present? && birthdate&.present?)
            sql << 'pseudo_id2 in (?)'
            values << pseudo_ids_list.collect(&:third).compact
          end
          scope = params[:scope] || Ppatient
          ppats = scope.where(sql.join(' or '), *values).limit(params[:limit])
          keys = nil if FIXUP_PRESCRIPTION_NULL_KEYID
          if keys
            # Cache lookup values (faster than a SQL join)
            # ppats = ppats.joins(:pseudonymisation_key).where(pseudonymisation_keys:
            #                                                    { key_name: keys })
            @keyids ||= {}
            @keyids[keys] ||= PseudonymisationKey.where(key_name: keys).
                              pluck(:pseudonymisation_keyid)
            ppats = ppats.where('pseudonymisation_keyid' => @keyids[keys])
          end
          ppats = ppats.joins(:e_batch).where(e_batch:
                                                { e_type: params[:e_types] }) if params[:e_types]
          ppats.each { |ppat| ppat.pseudonymisation_keyid ||= 1 } if FIXUP_PRESCRIPTION_NULL_KEYID
          ppats
        end
      end

      # Attempt to unlock the demographics associated with this patient
      # Returns true if the demographics are encrypted (not pseudonymised) or the
      # (nhsnumber) or (postcode + birthdate) match the details supplied.
      def unlock_demographics(nhsnumber, postcode, birthdate, context)
        # BRCA sets ppatient_rawdata.rawdata as a JSON-serialized hash
        # with the encrypted demographics having key encrypted_demog
        # and encrpyted rawtext having key encrypted_rawtext_demog
        # TODO: Refactor this into Pseudo::PpatientRawdata
        # TODO: Make rawdata be JSON, not just a .to_s of the hash
        matched_rawdata = ppatient_rawdata.rawdata.match(/"encrypted_demog"=>"([^"]*)"/)
        rawdata = if matched_rawdata
                    Base64.strict_decode64(matched_rawdata[1])
                  else
                    ppatient_rawdata.rawdata
                  end
        @demographics = JSON.parse(keystore.decrypt_record(
                                     pseudonymisation_key.key_name, :demographics,
                                     ppatient_rawdata.decrypt_key, rawdata,
                                     nhsnumber, postcode, birthdate, context
                                   ))
        true
      rescue OpenSSL::Cipher::CipherError
        false
      rescue ArgumentError => e
        raise if e.message == 'Unknown context'

        false
      end

      def demographics
        raise(ArgumentError, 'Demographics locked') unless @demographics
        @demographics
      end

      # Lock the demographics associated with this patient
      def lock_demographics
        @demographics = nil
      end

      # Extract birthdate from demographics
      # birthdate is usually stored in demographics hash in YYYY-MM-DD format
      # but sometimes stored in dateofbirth in ISO format e.g. "1999-12-31T00:00:00.000+01:00"
      def demographics_birthdate_yyyymmdd
        raise(ArgumentError, 'Demographics locked') unless @demographics

        if @demographics.key?('birthdate')
          @demographics['birthdate']
        elsif @demographics.key?('dateofbirth')
          begin
            Date.parse(@demographics['dateofbirth']).strftime('%Y-%m-%d')
          rescue Date::Error
            nil
          end
        end
        # Implicitly else nil
      end

      # Unpack the demographics for this patient, and confirm the match
      # :perfect if exact match on NHS number and date of birth
      # :fuzzy if exact on NHS number only, and years of birth are within 14 years of each other
      # :veryfuzzy if exact on NHS number only
      # :new otherwise
      def match_demographics(nhsnumber, postcode, birthdate)
        unlock_demographics(nhsnumber, postcode, birthdate, :match) unless @demographics
        return :new unless @demographics

        demographics_birthdate = demographics_birthdate_yyyymmdd
        if nhsnumber.present? && nhsnumber == @demographics['nhsnumber']
          if birthdate.present?
            return :perfect if birthdate == demographics_birthdate
            if (year1 = birthdate.to_s[0..3]).match?(/\A[0-9]{4}\z/) &&
               (year2 = demographics_birthdate.to_s[0..3]).match?(/\A[0-9]{4}\z/) &&
               (year2.to_i - year1.to_i).abs <= 14
              return :fuzzy
            end
          end
          :veryfuzzy
        elsif postcode.present? && birthdate.present? && postcode == @demographics['postcode'] &&
              birthdate == demographics_birthdate
          :fuzzy_postcode
        else
          :new
        end
      end
    end
  end
end
