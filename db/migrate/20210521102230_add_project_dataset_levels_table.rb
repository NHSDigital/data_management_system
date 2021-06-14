# plan.io 25873 - Add project_dataset_levels table
class AddProjectDatasetLevelsTable < ActiveRecord::Migration[6.0]
  def change
    create_table :project_dataset_levels do |t|
      t.timestamps

      t.references :project_dataset, foreign_key: true
      t.integer :access_level_id
      t.date :expiry_date
      t.boolean :approved
      t.boolean :selected
    end
  end
end
