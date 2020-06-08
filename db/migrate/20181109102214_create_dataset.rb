class CreateDataset < ActiveRecord::Migration[5.2]
  def change
    create_table :datasets do |t|
      t.string :name
      t.string :full_name
      t.string :description

      t.timestamps
    end
  end
end
