class CreateXmlAttribute < ActiveRecord::Migration[5.2]
  def change
    create_table :xml_attributes do |t|
      t.string :default
      t.string :fixed
      t.string :form
      t.string :attribute_id
      t.string :name
      t.string :ref
      t.string :type
      t.string :use

      t.timestamps
    end
  end
end
