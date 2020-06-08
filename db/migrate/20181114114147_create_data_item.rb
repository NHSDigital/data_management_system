class CreateDataItem < ActiveRecord::Migration[5.2]
  def change
    create_table :data_items do |t|
      t.string :name # xsd element name
      t.string :identifier # e.g CR0010
      t.string :annotation # e.g NHS NUMBER
      t.string :description # e.g For Linkage Purposes NHS NUMBER etc
      t.integer :min_occurs
      t.integer :max_occurs
      t.boolean :common
      t.integer :entity_id, null: true
      t.integer :xml_type_id, null: true
      t.integer :data_dictionary_element_id, null: true

      t.timestamps
    end
  end
end
