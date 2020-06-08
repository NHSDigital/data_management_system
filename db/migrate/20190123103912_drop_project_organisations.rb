class DropProjectOrganisations < ActiveRecord::Migration[5.2]
  def up
    drop_table :project_organisations
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
