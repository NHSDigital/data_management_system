# plan.io 27551 - add status_id to project_dataset_level table
class AddStatusIdToProjectDatasetLevel < ActiveRecord::Migration[6.0]
  def change
    add_column :project_dataset_levels, :status_id, :integer
  end
end
