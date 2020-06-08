class AddProjectNodeIdToProjectComment < ActiveRecord::Migration[5.2]
  def change
    add_column :project_comments, :project_node_id, :integer
  end
end
