class CreateProjectTypeDataset < ActiveRecord::Migration[6.0]
  def change
    create_table :project_type_datasets do |t|
      t.references :project_type, foreign_key: true
      t.references :dataset, foreign_key: true

      t.timestamps
    end
  end
end
