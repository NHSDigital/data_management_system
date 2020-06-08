class CreateGroup < ActiveRecord::Migration[5.2]
  def change
    create_table :groups do |t|
      t.string :name
      t.string :shortdesc
      t.string :description
      t.integer :dataset_version_id
      t.integer :sort

      t.timestamps
    end
  end
end
