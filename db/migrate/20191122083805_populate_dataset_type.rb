class PopulateDatasetType < ActiveRecord::Migration[6.0]
  include MigrationHelper
  def change
    add_lookup DatasetType, 1, name: 'Non XML Schema'
    add_lookup DatasetType, 2, name: 'XML Schema'
  end
end
