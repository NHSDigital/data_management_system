# Remove approved and current columns from project_dataset_levels - replaced by status_id
class RemoveApprovedCurrentFromProjectDatasetLevel < ActiveRecord::Migration[6.0]
  def change
    remove_column :project_dataset_levels, :current, :boolean, default: true
    remove_column :project_dataset_levels, :approved, :boolean
  end
end
