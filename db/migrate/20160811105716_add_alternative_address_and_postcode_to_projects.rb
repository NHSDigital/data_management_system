class AddAlternativeAddressAndPostcodeToProjects < ActiveRecord::Migration[5.0]
  def change
    add_column :projects, :alternative_data_access_address, :string
    add_column :projects, :alternative_data_access_postcode, :string
  end
end
