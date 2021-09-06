# Create ProjectDatasetLevelStatus Lookup Table
class CreateProjectDatasetLevelStatus < ActiveRecord::Migration[6.0]
  def change
    create_table :project_dataset_level_statuses do |t|
      t.string :value
      t.string :description

      t.timestamps
    end
  end
end
