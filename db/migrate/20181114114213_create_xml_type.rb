class CreateXmlType < ActiveRecord::Migration[5.2]
  def change
    create_table :xml_types do |t|
      t.string :name
      t.string :annotation
      t.integer :min_length
      t.integer :max_length
      t.string :pattern
      t.string :restriction
      t.string :attribute_name
      t.integer :namespace_id

      t.timestamps
    end
  end
end
