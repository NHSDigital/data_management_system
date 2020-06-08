module Pseudo
  class KeyStoreLocal
    # A single key instance, that can encrypt / decrypt / pseudonymise patient data
    class Entry
      def initialize(salt_id, salt_demog, salt_clinical, salt_rawdata)
        @salt_id = salt_id
        @salt_demog = salt_demog
        @salt_clinical = salt_clinical
        @salt_rawdata = salt_rawdata
      end

      def pseudo_ids(_nhsnumber, _current_postcode, _birthdate)
        # Assumes arguments already sanitised by KeyStoreLocal
        raise 'The method pseudo_ids must be overridden by subclasses'
      end

      # rubocop:disable Metrics/ParameterLists # Lightweight API for trusted crypto support
      def decrypt_record(_data_type, _decrypt_key, _rawdata,
                         _nhsnumber, _current_postcode, _birthdate)
        # Assumes arguments already sanitised by KeyStoreLocal
        raise 'The method decrypt_record must be overridden by subclasses'
      end
      # rubocop:enable Metrics/ParameterLists

      def encrypt_record(_data_type, _rawvalue, _nhsnumber, _current_postcode, _birthdate)
        # Assumes arguments already sanitised by KeyStoreLocal
        raise 'The method decrypt_record must be overridden by subclasses'
      end

      # Does this key support decryption without matching demographics?
      def decrypts_without_demographics?
        raise 'The method decrypts_without_demographics? must be overridden by subclasses'
      end

      private

      # TODO: Maybe move methods decrypt_data and decrypt_data64
      #       to NdrPseudonymise::SimplePseudonymisation
      def decrypt_data(key, data)
        unless key =~ /[0-9a-f]{32}/
          raise(ArgumentError,
                'Expected key to contain at least 256 bits of hex characters (0-9, a-f)')
        end
        aes = OpenSSL::Cipher.new('AES-256-CBC')
        aes.decrypt
        aes.key = Digest::SHA256.digest(key.chomp)
        (aes.update(data) + aes.final)
      end

      def decrypt_data64(key, data)
        decrypt_data(key, Base64.strict_decode64(data))
      end
    end
  end
end
