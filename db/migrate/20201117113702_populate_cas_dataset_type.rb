class PopulateCasDatasetType < ActiveRecord::Migration[6.0]
  include MigrationHelper
  def change
    add_lookup DatasetType, 5, name: 'cas'
  end
end
