class RenameOrganisations < ActiveRecord::Migration[5.2]
  def change
    rename_table :organisations, :project_organisations
  end
end
