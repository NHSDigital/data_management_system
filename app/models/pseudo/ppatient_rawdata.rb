# pseudonymised patient rawdata table
module Pseudo
  class PpatientRawdata < ActiveRecord::Base
    # one-to-many relationship from PPATIENT_RAWDATA to PPATIENT,
    # so that if the raw data is identical, we can optimise storage.
    has_many :ppatients

    # For efficient binary database storage, key_bundle is stored as binary data
    # (multiples of 80 bytes)

    validates :decrypt_key, presence: true
  end
end
