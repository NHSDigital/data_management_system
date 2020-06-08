module Pseudo
  # pseudonymised patient table
  class Ppatient < ActiveRecord::Base
    include EncryptDemographics

    has_one :birth_data
    has_one :death_data
    has_one :molecular_data
    has_many :prescription_data

    # more than one patient might have the same raw data
    belongs_to :ppatient_rawdata
    belongs_to :pseudonymisation_key, foreign_key: 'pseudonymisation_keyid'

    belongs_to :e_batch

    validates :pseudo_id1, presence: true

    scope :birthdata, -> { where(type: 'Pseudo::Pbirth') }
    scope :deathdata, -> { where(type: 'Pseudo::Pdeath') }
    scope :moleculardata, -> { where(type: 'Pseudo::Pmolecular') }
    scope :prescriptiondata, -> { where(type: 'Pseudo::Prescription') }

    # Define a key store for this class, and all its subclasses
    # (This only needs to be set if encrypting / pseudonymising / matching
    #  / decrypting identifiable data.)
    # rubocop:disable Style/ClassVars # Subclasses need access to the same keystore
    def self.keystore=(keystore)
      @@keystore = keystore
    end
    # rubocop:enable Style/ClassVars

    private_class_method def self.keystore
      @@keystore
    end

    private

    def keystore
      @@keystore
    end
  end
end
