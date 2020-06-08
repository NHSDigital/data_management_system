class RemoveFieldsFromProject < ActiveRecord::Migration[5.0]
  def change
    remove_column :projects, :s42_of_srsa, :boolean
    remove_column :projects, :alternative_data_access_address, :string
    remove_column :projects, :alternative_data_access_postcode, :string
    remove_column :projects, :outputs, :string
  end
end
