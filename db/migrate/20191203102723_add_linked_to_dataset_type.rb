class AddLinkedToDatasetType < ActiveRecord::Migration[6.0]
  include MigrationHelper
  def change
    add_lookup DatasetType, 3, name: 'Linked'
  end
end
