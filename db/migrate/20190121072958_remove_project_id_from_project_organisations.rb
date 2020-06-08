class RemoveProjectIdFromProjectOrganisations < ActiveRecord::Migration[5.2]
  def up
    remove_foreign_key :project_organisations, column: :project_id
    remove_column :project_organisations, :project_id
  end

  def down; end
end
