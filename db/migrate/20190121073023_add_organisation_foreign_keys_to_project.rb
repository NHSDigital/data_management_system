class AddOrganisationForeignKeysToProject < ActiveRecord::Migration[5.2]
  def change
    add_column :projects, :applicant_organisation_id, :integer, index: true
    add_foreign_key :projects, :project_organisations, column: :applicant_organisation_id

    add_column :projects, :sponsor_organisation_id, :integer, index: true
    add_foreign_key :projects, :project_organisations, column: :sponsor_organisation_id

    add_column :projects, :funder_organisation_id, :integer, index: true
    add_foreign_key :projects, :project_organisations, column: :funder_organisation_id

    add_column :projects, :data_processing_organisation_id, :integer, index: true
    add_foreign_key :projects, :project_organisations, column: :data_processing_organisation_id
  end
end
