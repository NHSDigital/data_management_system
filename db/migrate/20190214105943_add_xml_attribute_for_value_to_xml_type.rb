class AddXmlAttributeForValueToXmlType < ActiveRecord::Migration[5.2]
  def change
    add_column :xml_types, :xml_attribute_for_value_id, :integer
  end
end
