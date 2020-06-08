class CreateProjectClassification < ActiveRecord::Migration[5.0]
  def change
    create_table :project_classifications do |t|
      t.integer  :project_id
      t.integer  :classification_id
    end
    add_index :project_classifications, [:project_id]
    add_index :project_classifications, [:classification_id]
  end
end
