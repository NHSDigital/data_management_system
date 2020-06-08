module Pseudo
  class KeyStoreLocal
    # Encrypt / decrypt patient symmetrically, and generate pseudo_ids for matching.
    class Encrypt < Entry
      def pseudo_ids(nhsnumber, current_postcode, birthdate)
        # TODO: Write more efficient method in ndr_pseudonymise gem
        pseudo_id1, pseudo_id2, _key_bundle, _rowid, _demog_key, _clinical_key = \
          NdrPseudonymise::SimplePseudonymisation.generate_keys(
            @salt_id, @salt_demog,
            @salt_clinical || NdrPseudonymise::SimplePseudonymisation.random_key,
            nhsnumber, current_postcode, birthdate
          )
        [pseudo_id1, pseudo_id2]
      end

      # rubocop:disable Metrics/ParameterLists # Lightweight API for trusted crypto support
      def decrypt_record(data_type, decrypt_key, rawdata, _nhsnumber, _current_postcode, _birthdate)
        # Assumes arguments already sanitised by KeyStoreLocal
        real_key = NdrPseudonymise::SimplePseudonymisation.data_hash(decrypt_key, salt(data_type))
        decrypt_data(real_key, rawdata)
      end
      # rubocop:enable Metrics/ParameterLists

      def encrypt_record(data_type, rawvalue, nhsnumber, current_postcode, birthdate)
        # Assumes arguments already sanitised by KeyStoreLocal
        pseudo_id1, pseudo_id2 = pseudo_ids(nhsnumber, current_postcode, birthdate)
        # Binary key encoding (rather than hex) for compactness
        decrypt_key = [NdrPseudonymise::SimplePseudonymisation.random_key].pack('H*')
        real_key = NdrPseudonymise::SimplePseudonymisation.data_hash(decrypt_key, salt(data_type))
        encrypted_data = NdrPseudonymise::SimplePseudonymisation.encrypt_data(real_key, rawvalue)
        [pseudo_id1, pseudo_id2, decrypt_key, encrypted_data]
      end

      # Does this key support decryption without matching demographics?
      def decrypts_without_demographics?
        true
      end

      private

      def salt(data_type)
        case data_type
        when :demographics then @salt_demog
        when :clinical then @salt_clinical
        when :rawdata then @salt_rawdata
        else raise "Unknown data_type #{data_type}"
        end
      end
    end
  end
end
