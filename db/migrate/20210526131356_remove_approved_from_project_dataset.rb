# Remove approved column from project_dataset - now on project_dataset_level instead
class RemoveApprovedFromProjectDataset < ActiveRecord::Migration[6.0]
  def change
    remove_column :project_datasets, :approved, :boolean
  end
end
