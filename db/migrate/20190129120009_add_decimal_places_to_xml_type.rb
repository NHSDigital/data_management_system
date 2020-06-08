class AddDecimalPlacesToXmlType < ActiveRecord::Migration[5.2]
  def change
    add_column :xml_types, :decimal_places, :integer
  end
end
