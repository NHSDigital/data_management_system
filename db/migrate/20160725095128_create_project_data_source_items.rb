class CreateProjectDataSourceItems < ActiveRecord::Migration[5.0]
  def change
    create_table :project_data_source_items do |t|
      t.references :project, foreign_key: true
      t.references :data_source_item, foreign_key: true

      t.timestamps
    end
  end
end
