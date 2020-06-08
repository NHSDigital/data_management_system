class CreateDataSourceItems < ActiveRecord::Migration[5.0]
  def change
    create_table :data_source_items do |t|
      t.string :name
      t.string :description
      t.string :governance
      t.integer :data_source_id
      t.timestamps
    end
  end
end
