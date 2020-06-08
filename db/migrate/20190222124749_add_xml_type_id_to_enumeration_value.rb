class AddXmlTypeIdToEnumerationValue < ActiveRecord::Migration[5.2]
  def change
    add_column :enumeration_values, :xml_type_id, :integer
  end
end
