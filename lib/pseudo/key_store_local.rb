module Pseudo
  # Provide limited access to encryption / decryption / pseudonymisation.
  # This may be implemented by a local in-memory keystore, or by communicating
  # with a trusted module.
  class KeyStoreLocal < KeyStore
    NHSNUMBER_RE = /\A([0-9]{10})?\Z/
    POSTCODE_RE = /\A[A-Z0-9 ]*\Z/
    DATE_RE = /\A(\d{4}-[01]\d-[0-3]\d|)\Z/
    # Could be more specific with DATE_RE, e.g. https://stackoverflow.com/questions/28020805
    # %r{^(?:[1-9]\d{3}-(?:(?:0[1-9]|1[0-2])-(?:0[1-9]|1\d|2[0-8])|(?:0[13-9]|1[0-2])-(?:29|30)|
    #    (?:0[13578]|1[02])-31)|(?:[1-9]\d(?:0[48]|[2468][048]|[13579][26])|
    #    (?:[2468][048]|[13579][26])00)-02-29)}x
    DATA_TYPES = %i(demographics clinical rawdata).freeze
    CONTEXTS = %i(create export match).freeze

    def initialize(bundle)
      @bundle = bundle
    end

    def pseudo_ids(key_names, nhsnumber, current_postcode, birthdate, context)
      raise(ArgumentError, 'Unknown context') unless CONTEXTS.include?(context)
      raise 'Invalid NHS number' unless nhsnumber.is_a?(String) && nhsnumber =~ NHSNUMBER_RE
      raise 'Invalid postcode' unless current_postcode.is_a?(String) &&
                                      current_postcode =~ POSTCODE_RE
      raise 'Invalid birthdate' unless birthdate.is_a?(String) && birthdate =~ DATE_RE
      key_names.collect do |key_name|
        ([key_name] + find_key(key_name).pseudo_ids(nhsnumber, current_postcode, birthdate))
      end
    end

    # Decrypt demographics, clinical data or rawdata
    # data_type should be one of :demographics, :clinical, :rawdata
    # rubocop:disable Metrics/ParameterLists # Lightweight API for trusted crypto support
    def decrypt_record(key_name, data_type, decrypt_key, rawdata, nhsnumber, current_postcode,
                       birthdate, context)
      raise(ArgumentError, 'Unknown context') unless CONTEXTS.include?(context)
      raise(ArgumentError, 'Unknown data_type') unless DATA_TYPES.include?(data_type)
      raise 'Invalid NHS number' unless nhsnumber.is_a?(String) && nhsnumber =~ NHSNUMBER_RE
      raise 'Invalid postcode' unless current_postcode.is_a?(String) &&
                                      current_postcode =~ POSTCODE_RE
      raise 'Invalid birthdate' unless birthdate.is_a?(String) && birthdate =~ DATE_RE
      find_key(key_name).decrypt_record(data_type, decrypt_key, rawdata, nhsnumber,
                                        current_postcode, birthdate)
    end
    # rubocop:enable Metrics/ParameterLists

    # Encrypts rawvalue, and returns (pseudo_id1, pseudo_id2, decrypt_key, rawdata)
    # data_type should be one of :demographics, :clinical, :rawdata
    # rubocop:disable Metrics/ParameterLists # Lightweight API for trusted crypto support
    def encrypt_record(key_name, data_type, rawvalue, nhsnumber, current_postcode, birthdate,
                       context)
      raise(ArgumentError, 'Unknown context') unless CONTEXTS.include?(context)
      raise(ArgumentError, 'Unknown data_type') unless DATA_TYPES.include?(data_type)
      raise 'Invalid NHS number' unless nhsnumber.is_a?(String) && nhsnumber =~ NHSNUMBER_RE
      raise 'Invalid postcode' unless current_postcode.is_a?(String) &&
                                      current_postcode =~ POSTCODE_RE
      raise 'Invalid birthdate' unless birthdate.is_a?(String) && birthdate =~ DATE_RE
      find_key(key_name).encrypt_record(data_type, rawvalue, nhsnumber, current_postcode, birthdate)
    end
    # rubocop:enable Metrics/ParameterLists

    # Does this key support decryption without matching demographics?
    def decrypts_without_demographics?(key_name)
      find_key(key_name).decrypts_without_demographics?
    end

    private

    # Returns a Pseudo::KeyStoreLocal::Entry
    def find_key(key_name)
      @allkeys ||= {}
      @allkeys[key_name] ||= build_key_store_entry(key_name)
    end

    # Returns a Pseudo::KeyStore::Entry for a particular key
    def build_key_store_entry(key_name)
      key_attributes = @bundle.extract(key_name.to_sym)
      raise("Unknown key #{key_name}") unless key_attributes

      klass = case key_attributes[:mode]
              when 'encrypt'
                Pseudo::KeyStoreLocal::Encrypt
              when 'pseudonymise_nhsnumber_only'
                Pseudo::KeyStoreLocal::PseudonymiseNhsOnly
              when 'pseudonymise_nhsnumber_postcode_birthdate'
                # decrypt_key is a key bundle (binary encoded, not base-64)
                Pseudo::KeyStoreLocal::PseudonymiseNhsPostcodeBirthdate
              else
                raise("Unknown mode #{key_attributes[:mode]}")
              end
      klass.new(key_attributes[:salt1], key_attributes[:salt2], # salt_id, salt_demog
                key_attributes[:salt3], key_attributes[:salt4]) # salt_clinical, salt_rawdata
    end
  end
end
