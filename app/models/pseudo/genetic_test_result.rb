module Pseudo
  class GeneticTestResult < ActiveRecord::Base
    belongs_to :molecular_data
    validates :molecular_data_id, presence: true
  end
end
