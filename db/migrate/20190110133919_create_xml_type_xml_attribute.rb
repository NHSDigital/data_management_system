class CreateXmlTypeXmlAttribute < ActiveRecord::Migration[5.2]
  def change
    create_table :xml_type_xml_attributes do |t|
      t.references :xml_type, foreign_key: true
      t.references :xml_attribute, foreign_key: true

      t.timestamps
    end
  end
end
