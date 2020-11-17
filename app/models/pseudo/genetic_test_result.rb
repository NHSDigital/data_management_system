module Pseudo
  class GeneticTestResult < ActiveRecord::Base
    belongs_to :molecular_data
    validates :molecular_data_id, presence: true
    has_many :genetic_sequence_variants, dependent: :destroy, inverse_of: :genetic_test_result

    NEGATIVE_STATUS = 1
    POSITIVE_STATUS = 2

    scope :negative, -> { where('teststatus = ?', NEGATIVE_STATUS) }
    scope :positive, -> { where('teststatus = ?', POSITIVE_STATUS) }
  end
end
