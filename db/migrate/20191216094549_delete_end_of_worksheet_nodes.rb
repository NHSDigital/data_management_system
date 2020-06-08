class DeleteEndOfWorksheetNodes < ActiveRecord::Migration[6.0]
  def up
    Nodes::Group.where('name ILIKE ?', '%End of sheet%').delete_all
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
