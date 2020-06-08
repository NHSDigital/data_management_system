class AddProjectTypeIdToProjects < ActiveRecord::Migration[5.2]
  def change
    add_column :projects, :project_type, :integer, default: 1
  end
end
