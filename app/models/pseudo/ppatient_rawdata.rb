# pseudonymised patient rawdata table
module Pseudo
  class PpatientRawdata < ActiveRecord::Base
    DECRYPT_KEY_SIZES = [0, 32, 80, 160, 320]

    # one-to-many relationship from PPATIENT_RAWDATA to PPATIENT,
    # so that if the raw data is identical, we can optimise storage.
    has_many :ppatients

    # For efficient binary database storage, key_bundle is stored as binary data
    # (multiples of 80 bytes)
    validate :decrypt_key_should_have_valid_length

    # Ensure packed decrypt key size is a known multiple of 80 bytes (for pseudonymisation)
    # or 32 bytes (for a 256-bit symmetric key for encrypted demographics)
    def decrypt_key_should_have_valid_length
      return if DECRYPT_KEY_SIZES.include?(decrypt_key&.size)

      errors.add(:decrypt_key, "decrypt_key length must be one of #{DECRYPT_KEY_SIZES}")
    end
  end
end
