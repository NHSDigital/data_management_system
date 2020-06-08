module Pseudo
  class GeneticSequenceVariant < ActiveRecord::Base
    belongs_to :genetic_test_result
    validates :genetic_test_result_id, presence: true
  end
end
