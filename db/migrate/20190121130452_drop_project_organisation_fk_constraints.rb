class DropProjectOrganisationFkConstraints < ActiveRecord::Migration[5.2]
  def up
    remove_foreign_key :projects, column: :applicant_organisation_id
    remove_foreign_key :projects, column: :sponsor_organisation_id
    remove_foreign_key :projects, column: :funder_organisation_id
    remove_foreign_key :projects, column: :data_processing_organisation_id
  end

  def down
    add_foreign_key :projects, :project_organisations, column: :applicant_organisation_id
    add_foreign_key :projects, :project_organisations, column: :sponsor_organisation_id
    add_foreign_key :projects, :project_organisations, column: :funder_organisation_id
    add_foreign_key :projects, :project_organisations, column: :data_processing_organisation_id
  end
end
