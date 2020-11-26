class PopulateDatasetApproverDatasetRole < ActiveRecord::Migration[6.0]
  include MigrationHelper
  def change
    add_lookup DatasetRole, 1, sort: 1, name: 'Approver'
  end
end
