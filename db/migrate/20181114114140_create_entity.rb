class CreateEntity < ActiveRecord::Migration[5.2]
  def change
    create_table :entities do |t|
      t.string :name # Xsd element name
      t.string :title # User title
      t.string :description # User full description
      t.integer :parent_id
      t.integer :dataset_version_id
      t.integer :min_occurs
      t.integer :max_occurs
      t.integer :sort

      t.timestamps
    end
  end
end
