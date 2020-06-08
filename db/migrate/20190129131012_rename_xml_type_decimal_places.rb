class RenameXmlTypeDecimalPlaces < ActiveRecord::Migration[5.2]
  def change
    rename_column :xml_types, :decimal_places, :fractiondigits
  end
end
