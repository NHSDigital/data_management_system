module Pseudo
  # pseudonymisation key table
  class PseudonymisationKey < ActiveRecord::Base
    belongs_to :zprovider, optional: true
    belongs_to :ze_type, foreign_key: 'e_type', optional: true

    # Helper method, to pack a string decrypt_key (base64 with spaces) into a binary representation
    def self.pack_decrypt_key(unpacked_key)
      packed_key = unpacked_key.split.collect { |s| Base64.strict_decode64(s) }.join
      unless (packed_key.size % 80).zero?
        raise(ArgumentError, "Invalid key length #{packed_key.size}")
      end

      packed_key
    end

    # Helper method, unpack a binary decrypt_key into a string representation (base64 with spaces)
    def self.unpack_decrypt_key(packed_key)
      unless (packed_key.size % 80).zero?
        raise(ArgumentError, "Invalid key length #{packed_key.size}")
      end

      packed_key.chars.to_a.each_slice(80).collect { |x| Base64.strict_encode64(x.join) }.join(' ')
    end
  end
end
