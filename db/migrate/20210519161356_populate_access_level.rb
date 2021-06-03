# Populate access_level lookup table
class PopulateAccessLevel < ActiveRecord::Migration[6.0]
  include MigrationHelper

  class AccessLevel < ApplicationRecord
    attribute :value, :string
    attribute :description, :string
  end

  def change
    add_lookup AccessLevel, 1, value: '1', description: 'Level 1'
    add_lookup AccessLevel, 2, value: '2', description: 'Level 2'
    add_lookup AccessLevel, 3, value: '3', description: 'Level 3'
  end
end
