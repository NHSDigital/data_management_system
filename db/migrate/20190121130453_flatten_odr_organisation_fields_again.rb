class FlattenOdrOrganisationFieldsAgain < ActiveRecord::Migration[5.2]
  def change
    remove_column :projects, :applicant_organisation_id, :integer
    remove_column :projects, :sponsor_organisation_id, :integer
    remove_column :projects, :funder_organisation_id, :integer
    remove_column :projects, :data_processing_organisation_id, :integer

    add_column :projects, :organisation_name, :string
    add_column :projects, :organisation_department, :string
    add_column :projects, :organisation_add1, :string
    add_column :projects, :organisation_add2, :string
    add_column :projects, :organisation_city, :string
    add_column :projects, :organisation_postcode, :string
    add_column :projects, :organisation_country_id, :string, index: true
    add_column :projects, :organisation_type_id, :integer, index: true
    add_column :projects, :organisation_type_other, :string
    add_foreign_key :projects, :countries, column: :organisation_country_id
    add_foreign_key :projects, :organisation_types, column: :organisation_type_id

    add_column :projects, :sponsor_name, :string
    add_column :projects, :sponsor_department, :string
    add_column :projects, :sponsor_add1, :string
    add_column :projects, :sponsor_add2, :string
    add_column :projects, :sponsor_city, :string
    add_column :projects, :sponsor_postcode, :string
    add_column :projects, :sponsor_country_id, :string, index: true
    add_foreign_key :projects, :countries, column: :sponsor_country_id

    add_column :projects, :funder_name, :string
    add_column :projects, :funder_department, :string
    add_column :projects, :funder_add1, :string
    add_column :projects, :funder_add2, :string
    add_column :projects, :funder_city, :string
    add_column :projects, :funder_postcode, :string
    add_column :projects, :funder_country_id, :string, index: true
    add_foreign_key :projects, :countries, column: :funder_country_id

    add_column :projects, :data_processor_name, :string
    add_column :projects, :data_processor_department, :string
    add_column :projects, :data_processor_add1, :string
    add_column :projects, :data_processor_add2, :string
    add_column :projects, :data_processor_city, :string
    add_column :projects, :data_processor_postcode, :string
    add_column :projects, :data_processor_country_id, :string, index: true
    add_foreign_key :projects, :countries, column: :data_processor_country_id

    add_column :projects, :processing_territory_id, :integer, index: true
    add_foreign_key :projects, :processing_territories
    add_column :projects, :processing_territory_other, :string
    add_column :projects, :dpa_org_code, :string
    add_column :projects, :dpa_org_name, :string
    add_column :projects, :dpa_registration_end_date, :datetime
    add_column :projects, :security_assurance_id, :integer, index: true
    add_foreign_key :projects, :security_assurances
    add_column :projects, :ig_code, :string
    add_column :projects, :ig_score, :integer
    add_column :projects, :ig_tooklit_version, :string

    add_column :projects, :processing_territory_outsourced_other, :string
    add_column :projects, :dpa_org_code_outsourced, :string
    add_column :projects, :dpa_org_name_outsourced, :string
    add_column :projects, :dpa_registration_end_date_outsourced, :datetime
    add_column :projects, :security_assurances_outsourced_id, :integer, index: true
    add_foreign_key :projects, :security_assurances, column: :security_assurances_outsourced_id
    add_column :projects, :ig_code_outsourced, :string
    add_column :projects, :ig_score_outsourced, :integer
    add_column :projects, :ig_tooklit_version_outsourced, :string
  end
end
