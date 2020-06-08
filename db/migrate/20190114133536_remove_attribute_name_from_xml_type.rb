class RemoveAttributeNameFromXmlType < ActiveRecord::Migration[5.2]
  def change
    remove_column :xml_types, :attribute_name, :string
  end
end
