class PopulateIdentifiabilityLevels < ActiveRecord::Migration[5.2]
  include MigrationHelper

  class IdentifiabilityLevel < ApplicationRecord
    attribute :value, :string
  end

  def change
    add_lookup IdentifiabilityLevel, 1, value: 'Personally Identifiable'
    add_lookup IdentifiabilityLevel, 2, value: 'De-personalised'
    add_lookup IdentifiabilityLevel, 3, value: 'Anonymous'
  end
end
