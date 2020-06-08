class AddTotaldigitsToXmlType < ActiveRecord::Migration[5.2]
  def change
    add_column :xml_types, :totaldigits, :integer
  end
end
