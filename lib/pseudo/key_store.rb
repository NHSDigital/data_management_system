module Pseudo
  # Provide limited access to encryption / decryption / pseudonymisation.
  # This may be implemented by a local in-memory keystore, or by communicating
  # with a trusted module.
  class KeyStore
    # Returns an array, where each element contains [key, pseudo_id1, pseudo_id2]
    def pseudo_ids(_key_names, _nhsnumber, _current_postcode, _birthdate, _context)
      raise 'The method pseudo_ids must be overridden by subclasses'
    end

    # Decrypt demographics, clinical data or rawdata
    # data_type should be one of :demographics, :clinical, :rawdata
    # rubocop:disable Metrics/ParameterLists # Lightweight API for trusted crypto support
    def decrypt_record(_key_name, _data_type, _decrypt_key, _rawdata,
                       _nhsnumber, _current_postcode, _birthdate, _context)
      raise 'The method decrypt_record must be overridden by subclasses'
    end
    # rubocop:enable Metrics/ParameterLists

    # Encrypts rawvalue, and returns (pseudo_id1, pseudo_id2, decrypt_key, rawdata)
    # data_type should be one of :demographics, :clinical, :rawdata
    # rubocop:disable Metrics/ParameterLists # Lightweight API for trusted crypto support
    def encrypt_record(_key_name, _data_type, _rawvalue,
                       _nhsnumber, _current_postcode, _birthdate, _context)
      raise 'The method encrypt_record must be overridden by subclasses'
    end
    # rubocop:enable Metrics/ParameterLists

    # Does this key support decryption without matching demographics?
    def decrypts_without_demographics?(_key_name)
      raise 'The method decrypts_without_demographics? must be overridden by subclasses'
    end
  end
end
