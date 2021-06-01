module Pseudo
  class KeyStoreLocal
    # Pseudonymise patients by NHS number, postcode and birthdate (e.g. BRCA molecular data)
    class PseudonymiseNhsPostcodeBirthdate < Entry
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
      def decrypt_record(data_type, decrypt_key, rawdata, nhsnumber, current_postcode, birthdate)
        # Assumes arguments already sanitised by KeyStoreLocal
        unless data_type == :demographics
          # TODO: Support rawtext key decryption
          raise 'PseudonymiseNhsPostcodeBirthdate decrypts only demographics'
        end

        # decrypt_key1 is encrypt(real_id1 + salt_demog, demog_key)
        # decrypt_key2 is encrypt(real_id2 + salt_demog, demog_key)
        # Depending on which demographics are provided, decrypt_key will be 0, 160 or 320 byyes
        real_id1 = "nhsnumber_#{nhsnumber}"
        real_id2 = "birthdate_postcode_#{birthdate}_#{current_postcode.delete(' ')}"
        case decrypt_key.size
        when 320
          # decrypt_key contains 4 x 80 byte keys:
          # demog_key1_encrypted, rawtext_key1_encrypted [both unlocked by nhsnumber]
          # demog_key2_encrypted, rawtext_key2_encrypted [both unlocked by postcode + birthdate]
          begin
            demog_key1 = decrypt_data(real_id1 + @salt_demog, decrypt_key[0..79])
            decrypt_data(demog_key1, rawdata)
          rescue OpenSSL::Cipher::CipherError, ArgumentError
            # nhsnumber decrypt failed, but birthdate + postcode may still match
            # Either the decryption of the demog_key1 fails, or it produces a junk demog_key1
            # which then fails with an ArgumentError in decrypt_key
            demog_key2 = decrypt_data(real_id2 + @salt_demog, decrypt_key[160..239])
            decrypt_data(demog_key2, rawdata)
          end
        when 160
          # decrypt_key contains 4 x 80 byte keys:
          # either demog_key1_encrypted, rawtext_key1_encrypted [both unlocked by nhsnumber]
          # or demog_key2_encrypted, rawtext_key2_encrypted [both unlocked by postcode + birthdate]
          # We can't tell which from context, so we need to try both
          begin
            demog_key1 = decrypt_data(real_id1 + @salt_demog, decrypt_key[0..79])
            decrypt_data(demog_key1, rawdata)
          rescue OpenSSL::Cipher::CipherError, ArgumentError
            demog_key2 = decrypt_data(real_id2 + @salt_demog, decrypt_key[0..79])
            begin
              decrypt_data(demog_key2, rawdata)
            rescue OpenSSL::Cipher::CipherError, ArgumentError
              raise(OpenSSL::Cipher::CipherError, 'Cannot decrypt with pseudo_id1 or pseudo_id2')
            end
          end
        when 0
          raise(OpenSSL::Cipher::CipherError, 'Insufficient original demographics to decrypt ' \
                                              'with pseudo_id1 or pseudo_id2')
        else
          raise(ArgumentError, "Unexpected decrypt_key.size #{decrypt_key.size}")
        end
      end
      # rubocop:enable Metrics/ParameterLists

      def encrypt_record(data_type, rawvalue, nhsnumber, current_postcode, birthdate)
        # Assumes arguments already sanitised by KeyStoreLocal
        unless data_type == :demographics
          # TODO: Support rawtext key encryption
          raise 'PseudonymiseNhsPostcodeBirthdate decrypts only demographics'
        end

        (pseudo_id1, pseudo_id2, key_bundle, _rowid, demog_key, _rawtext_key) =
          NdrPseudonymise::SimplePseudonymisation.generate_keys(@salt_id, @salt_demog,
                                                                @salt_rawdata,
                                                                nhsnumber, current_postcode,
                                                                birthdate)
        # For efficient binary database storage
        key_bundle = key_bundle.split.collect { |s| Base64.strict_decode64(s) }.join
        encrypted_demographics = NdrPseudonymise::SimplePseudonymisation.
                                 encrypt_data(demog_key, rawvalue)
        [pseudo_id1, pseudo_id2, key_bundle, encrypted_demographics]
      end

      # Does this key support decryption without matching demographics?
      def decrypts_without_demographics?
        false
      end
    end
  end
end
