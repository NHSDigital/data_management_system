class CreateDataItemGroup < ActiveRecord::Migration[5.2]
  def change
    create_table :data_item_groups do |t|
      t.references :data_item, foreign_key: true
      t.references :group, foreign_key: true

      t.timestamps
    end
  end
end
