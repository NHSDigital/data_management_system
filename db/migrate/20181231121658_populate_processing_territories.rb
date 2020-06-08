class PopulateProcessingTerritories < ActiveRecord::Migration[5.2]
  include MigrationHelper
  
  class ProcessingTerritory < ApplicationRecord
    attribute :value, :string
  end

  def change
    add_lookup ProcessingTerritory, 1, value: 'UK'
    add_lookup ProcessingTerritory, 2, value: 'EEU'
    add_lookup ProcessingTerritory, 3, value: 'Other'
  end
end
