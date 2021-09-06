# Populate ProjectDatasetLevelStatus Lookup
class PopulateProjectDatasetLevelStatus < ActiveRecord::Migration[6.0]
  include MigrationHelper

  class ProjectDatasetLevelStatus < ApplicationRecord
    attribute :value, :string
    attribute :description, :string
  end

  def change
    add_lookup ProjectDatasetLevelStatus, 1, value: '1', description: 'Requested'
    add_lookup ProjectDatasetLevelStatus, 2, value: '2', description: 'Approved'
    add_lookup ProjectDatasetLevelStatus, 3, value: '3', description: 'Rejected'
    add_lookup ProjectDatasetLevelStatus, 4, value: '4', description: 'Expiring'
    add_lookup ProjectDatasetLevelStatus, 5, value: '5', description: 'Expired'
  end
end
