class RenameProjectTypeOnProjects < ActiveRecord::Migration[5.2]
  def change
    rename_column :projects, :project_type, :project_type_id
  end
end
