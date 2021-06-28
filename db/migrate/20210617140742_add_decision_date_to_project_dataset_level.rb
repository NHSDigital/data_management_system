# plan.io 25663 - add decision_date to project_dataset_level table
class AddDecisionDateToProjectDatasetLevel < ActiveRecord::Migration[6.0]
  def change
    add_column :project_dataset_levels, :decided_at, :datetime
  end
end
