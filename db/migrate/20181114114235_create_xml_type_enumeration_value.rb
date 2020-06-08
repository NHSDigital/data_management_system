class CreateXmlTypeEnumerationValue < ActiveRecord::Migration[5.2]
  def change
    create_table :xml_type_enumeration_values do |t|
      t.references :xml_type, foreign_key: true
      t.references :enumeration_value, foreign_key: true

      t.timestamps
    end
  end
end
