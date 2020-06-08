module Pseudo
  class KeyStoreLocal
    # Pseudonymise patients by NHS number only (e.g. prescription data)
    class PseudonymiseNhsOnly < Entry
      def pseudo_ids(nhsnumber, _current_postcode, _birthdate)
        # Assumes arguments already sanitised by KeyStoreLocal
        # TODO: Refactorise into ndr_pseudonymise gem, in NdrPseudonymise::SimplePseudonymisation
        real_id1 = 'nhsnumber_' + nhsnumber
        pseudo_id1 = NdrPseudonymise::SimplePseudonymisation.data_hash(real_id1, @salt_id)
        [pseudo_id1, nil]
      end

      # rubocop:disable Metrics/ParameterLists # Lightweight API for trusted crypto support
      def decrypt_record(data_type, decrypt_key, rawdata, nhsnumber, _current_postcode, _birthdate)
        # Assumes arguments already sanitised by KeyStoreLocal
        raise 'PseudonymiseNhsOnly decrypts only demographics' unless data_type == :demographics
        # decrypt_key is encrypt(real_id1 + salt_demog, demog_key)
        demog_key1 = decrypt_data('nhsnumber_' + nhsnumber + @salt_demog, decrypt_key)
        decrypt_data(demog_key1, rawdata)
      end
      # rubocop:enable Metrics/ParameterLists

      def encrypt_record(data_type, rawvalue, nhsnumber, _current_postcode, _birthdate)
        # Assumes arguments already sanitised by KeyStoreLocal
        raise 'PseudonymiseNhsOnly encrypts only demographics' unless data_type == :demographics
        pseudo_id1, key_bundle, demog_key = NdrPseudonymise::SimplePseudonymisation.
                                            generate_keys_nhsnumber_demog_only(
                                              @salt_id, @salt_demog, nhsnumber
                                            )
        key_bundle = Base64.strict_decode64(key_bundle) # For efficient binary database storage
        encrypted_demographics = NdrPseudonymise::SimplePseudonymisation.
                                 encrypt_data(demog_key, rawvalue)
        [pseudo_id1, nil, key_bundle, encrypted_demographics]
      end

      # Does this key support decryption without matching demographics?
      def decrypts_without_demographics?
        false
      end
    end
  end
end
