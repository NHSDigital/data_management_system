# These are fields that we should be looking to clean up and/or normalise but for the purposes
# of migrating ODR off their Access db we should just take wholesale and clean up later.
class AddLegacyOdrFields < ActiveRecord::Migration[5.2]
  def change
    add_column :projects, :applicant_title, :string
    add_column :projects, :organisation_country, :string
    add_column :projects, :organisation_type, :string
    add_column :projects, :data_end_use, :string
    add_column :projects, :level_of_identifiability, :string
    add_column :projects, :s251_exemption, :string
    add_column :projects, :article6, :string
    add_column :projects, :article9, :string
    add_column :projects, :processing_territory, :string
    add_column :projects, :security_assurance_provided, :string
    add_column :projects, :assigned_to, :string
    add_column :projects, :amendment_type, :string
    add_column :projects, :spectrum_of_identifiability, :string

    add_column :contracts, :contract_type, :string
    add_column :contracts, :contract_version, :string
    add_column :contracts, :contract_status, :string
  end
end
