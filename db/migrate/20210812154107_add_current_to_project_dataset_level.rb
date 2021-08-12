# plan.io 27612 - add current to project_dataset_level table
class AddCurrentToProjectDatasetLevel < ActiveRecord::Migration[6.0]
  def change
    add_column :project_dataset_levels, :current, :boolean, default: true
  end
end
