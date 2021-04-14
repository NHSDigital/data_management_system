require 'ndr_import/table'
require 'ndr_import/file/registry'

module Export
  # Base class for exporting mapped MBIS birth / death data files, as weekly or annual extracts
  class BaseFile
    # Date of registration overlap period between M204 and LEDR data
    # LEDR includes a very few new 2017 registrations
    LEDR_M204_DOR_OVERLAP = /\A(2017|20180[1-3])/

    # ppat_rowids maps each ppatientid to a rowid
    def initialize(filename, e_type, ppats, filter = nil, ppatid_rowids: nil)
      @filename = filename
      @e_type = e_type
      @ppats = ppats
      @filter = filter
      @ppatid_rowids = ppatid_rowids || {}
    end

    private

    # Load the required mapping file based on @batch.e_type
    def table_mapping
      raise 'table_mapping method must be implemented by the subclass'
    end

    # Header rows (default to none)
    def header_rows
      []
    end

    # Footer rows (default to none)
    def footer_rows(_i)
      []
    end

    # Blank for utf-8, or e.g. 'windows-1252:utf-8' for windows-1252
    def csv_encoding
      nil
    end

    def csv_options
      { col_sep: ',', row_sep: "\r\n", force_quotes: true }
    end

    # Are there any earlier records with the same MBIS_ID that would have matched, and already
    # been sent?
    def already_extracted?(ppat, surveillance_code = nil)
      # We want a linear ordering and complete coverage, so can use e_batch_id
      # as sequence, even if this is not strictly temporal. We also don't want to bother with
      # patients in the same e_batch.
      # ???: Maybe base pseudo_id2 on mbism204id instead of postcode, for better matching.
      # TODO: Improve matching speed, by caching DOR range in EBatch#date_reference{1,2}
      #       and filtering batches against this
      ppat.unlock_demographics('', '', '', :export)
      nhsnumber = ppat.demographics['nhsnumber']
      postcode = ppat.demographics['postcode']
      birthdate = ppat.demographics['birthdate']
      matches = Pseudo::Ppatient.find_matching_ppatients(
        nhsnumber.to_s, postcode.to_s, birthdate.to_s, nil,
        scope: Pseudo::Ppatient.where('e_batchid < ?', ppat.e_batch_id),
        e_types: ppat.e_batch.e_type
      )
      # a = matches.size
      # Try harder for matches, when no exact matching was possible
      # Commonest LSOAR has 1289 entries in 2016 subset
      # Commonest DOR has 2944 entries in 2016 subset
      # Commonest DODDY has 17926 entries in 2016 subset
      # Commonest ICD10_1 has 42457 entries in 2016 subset
      # But the data shows that DOR never changes (for the same MBISM204ID)
      if matches.empty? && ppat.is_a?(Pseudo::Death) && nhsnumber.blank? &&
         [postcode, birthdate].any?(&:blank?)
        matches += Pseudo::Ppatient.find_matching_ppatients(
          '', '', '', nil,
          scope: Pseudo::Ppatient.where('e_batch_id < ?', ppat.e_batch_id).joins(:death_data).where(
            '(death_data.dor = :dor and death_data.lsoar = :lsoar) or
             (death_data.dor = :dor and death_data.icd_1 = :icd_1) or
             (death_data.lsoar = :lsoar and death_data.icd_1 = :icd_1)',
            ActiveSupport::HashWithIndifferentAccess.new(ppat.death_data.attributes)
          ), e_types: ppat.e_batch.e_type, match_blank: false, limit: 1000
        )
      end
      matches.each do |ppat2|
        ppat2.unlock_demographics('', '', '', :match) # Unlock mbism204id / ledrid for matching
        same_person = if ppat2.demographics['ledrid'] && ppat.demographics['ledrid']
                        ppat2.demographics['ledrid'] == ppat.demographics['ledrid']
                      elsif ppat2.demographics['mbism204id'] && ppat.demographics['mbism204id']
                        ppat2.demographics['mbism204id'] == ppat.demographics['mbism204id']
                      elsif ppat2.death_data.nil? || ppat.death_data.nil? ||
                            ppat2.death_data['dor'] !~ LEDR_M204_DOR_OVERLAP ||
                            ppat.death_data['dor'] !~ LEDR_M204_DOR_OVERLAP
                        # puts 'Skipping fallback for ppat2 vs ppat DOR: ' \
                        #      "#{ppat2.death_data['dor']} == #{ppat.death_data['dor']}"
                        false
                      else
                        # Fallback matching for M204 / LEDR transition
                        # using fields 197 (AGEC), 244 (LSOAR), 297 (DOR)
                        # Results in 99.91% agrement, based on 2017 to 2018-01 data
                        # $ (export LC_ALL=C; cut -d'|' -f1,197,244,297 MBISWEEKLY_Deaths_D1*txt \
                        #   |sort -u |cut -d'|' -f1|sort|uniq -d|wc -l)
                        # 298
                        # $ (export LC_ALL=C; cut -d'|' -f1 MBISWEEKLY_Deaths_D1*txt|sort -u |wc -l)
                        # 570502
                        # $ (export LC_ALL=C; cut -d'|' -f197,244,297 MBISWEEKLY_Deaths_D1*txt \
                        #   |sort -u |wc -l)
                        # 569990
                        # Note that AGEC has leading zeros in M204, but not LEDR
                        # Also, LSOAR is sometimes blank: if so, try ICD_1 + SNAMD
                        # If LSOAR is blank, try ICD_1 + SNAMD
                        # Resulted in 11 records from 'MBIS_PAN_FROM LEDR 01012018_PROD.txt'
                        # (which contained 68124 records), i.e. 0.016% missed potential duplicates
                        ppat2.death_data['dor'] == ppat.death_data['dor'] &&
                          ppat2.demographics['agec'].to_i == ppat.demographics['agec'].to_i &&
                          if ppat2.death_data['lsoar'] && ppat.death_data['lsoar']
                            ppat2.death_data['lsoar'] == ppat.death_data['lsoar']
                          elsif ppat2.death_data['icd_1'] == ppat.death_data['icd_1']
                            ppat2.death_data['icd_1'] == ppat.death_data['icd_1'] &&
                              ppat2.demographics['snamd'] == ppat.demographics['snamd']
                          else
                            ppat2.demographics['snamd'] == ppat.demographics['snamd']
                          end
                      end
        if same_person &&
           !(ppat2.demographics['ledrid'] && ppat.demographics['ledrid']) &&
           !(ppat2.demographics['mbism204id'] && ppat.demographics['mbism204id'])
          # puts 'Fallback matching was successful for ppat2 vs ppat DOR: ' \
          #      "#{ppat2.death_data['dor']} == #{ppat.death_data['dor']}"
          if ppat2.death_data['dor'].start_with?('2017') ||
             ppat.death_data['dor'].start_with?('2017')
            # TODO: keep testing, remove warning below?
            # May be best fixed by removing weekly death records, and only keeping gold standard
            # annual death registrations
            Rails.logger.debug('Unexpected fallback for ppat2 vs ppat DOR: ' \
                               "#{ppat2.death_data['dor']} == #{ppat.death_data['dor']} " \
                               "for #{ppat2.record_reference} / #{ppat.record_reference}")
          end
        end
        if same_person && match_row?(ppat2, surveillance_code) # Would already have matched
          # puts "Already matched #{ppat2.record_reference}, " \
          #      "not extracting #{ppat.record_reference}" if a.zero?
          return true
        end
      end
      false
    end

    # Row of fields to extract, or nil to skip this record
    def extract_row(_ppat, _i)
      raise 'extract_row method must be implemented by the subclass'
    end
  end
end
