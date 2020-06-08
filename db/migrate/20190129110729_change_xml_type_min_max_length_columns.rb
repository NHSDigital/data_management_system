class ChangeXmlTypeMinMaxLengthColumns < ActiveRecord::Migration[5.2]
  def change
    change_column :xml_types, :min_length, :decimal
    change_column :xml_types, :max_length, :decimal
  end
end
