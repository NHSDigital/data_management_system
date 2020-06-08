class AddProjectIdToProjectOrganisations < ActiveRecord::Migration[5.2]
  def change
    add_column :project_organisations, :project_id, :integer, index: true
    add_foreign_key :project_organisations, :projects
  end
end
