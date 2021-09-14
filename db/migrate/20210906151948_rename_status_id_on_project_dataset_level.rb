class RenameStatusIdOnProjectDatasetLevel < ActiveRecord::Migration[6.0]
  def change
    rename_column :project_dataset_levels, :status_id, :status
  end
end
