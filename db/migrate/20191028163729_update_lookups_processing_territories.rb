class UpdateLookupsProcessingTerritories < ActiveRecord::Migration[6.0]
  include MigrationHelper

  class ProcessingTerritory < ApplicationRecord
    attribute :value, :string
  end

  def change
    change_lookup ProcessingTerritory, 2, { value: 'EEU' }, { value: 'EEA' }
  end
end
