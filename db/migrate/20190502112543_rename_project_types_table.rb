class RenameProjectTypesTable < ActiveRecord::Migration[5.2]
  def change
    rename_table :project_types, :project_purposes
  end
end
