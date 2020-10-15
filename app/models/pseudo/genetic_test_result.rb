module Pseudo
  class GeneticTestResult < ActiveRecord::Base
    belongs_to :molecular_data
    validates :molecular_data_id, presence: true
    has_many :genetic_sequence_variants, dependent: :destroy, inverse_of: :genetic_test_result
  end
end
