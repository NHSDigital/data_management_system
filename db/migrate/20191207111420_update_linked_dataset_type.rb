class UpdateLinkedDatasetType < ActiveRecord::Migration[6.0]
  include MigrationHelper
  def change
    linked_id = DatasetType.find_by(name: 'Linked').id
    change_lookup DatasetType, linked_id, { name: 'Linked' }, { name: 'Table Specification' }
  end
end
