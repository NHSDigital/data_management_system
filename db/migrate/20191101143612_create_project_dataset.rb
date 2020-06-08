class CreateProjectDataset < ActiveRecord::Migration[6.0]
  def change
    create_table :project_datasets do |t|
      t.references :project, foreign_key: true
      t.references :dataset, foreign_key: true

      t.timestamps
    end
  end
end
