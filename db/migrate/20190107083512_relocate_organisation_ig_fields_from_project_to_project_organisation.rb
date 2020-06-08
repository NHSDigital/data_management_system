class RelocateOrganisationIgFieldsFromProjectToProjectOrganisation < ActiveRecord::Migration[5.2]
  def change
    add_column :project_organisations, :processing_territory_id, :integer, index: true
    add_foreign_key :project_organisations, :processing_territories
    add_column :project_organisations, :processing_territory_other, :string
    add_column :project_organisations, :dpa_org_code, :string
    add_column :project_organisations, :dpa_org_name, :string
    add_column :project_organisations, :dpa_registration_end_date, :datetime
    add_column :project_organisations, :security_assurance_id, :integer, index: true
    add_foreign_key :project_organisations, :security_assurances
    add_column :project_organisations, :ig_code, :string
    add_column :project_organisations, :ig_score, :integer
    add_column :project_organisations, :ig_tooklit_version, :string

    remove_foreign_key :projects, column: :processing_territory_id
    remove_foreign_key :projects, column: :security_assurance_id
    remove_column :projects, :processing_territory_id
    remove_column :projects, :processing_territory_other
    remove_column :projects, :dpa_org_code
    remove_column :projects, :dpa_org_name
    remove_column :projects, :dpa_registration_end_date
    remove_column :projects, :security_assurance_id
    remove_column :projects, :ig_code
    remove_column :projects, :ig_score
    remove_column :projects, :ig_tooklit_version

    remove_foreign_key :projects, column: :processing_territory_outsourced_id
    remove_foreign_key :projects, column: :security_assurances_outsourced_id
    remove_column :projects, :processing_territory_outsourced_id
    remove_column :projects, :processing_territory_outsourced_other
    remove_column :projects, :dpa_org_code_outsourced
    remove_column :projects, :dpa_org_name_outsourced
    remove_column :projects, :dpa_registration_end_date_outsourced
    remove_column :projects, :security_assurances_outsourced_id
    remove_column :projects, :ig_code_outsourced
    remove_column :projects, :ig_score_outsourced
    remove_column :projects, :ig_tooklit_version_outsourced
  end
end
