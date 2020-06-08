class AddApprovedToProjectNode < ActiveRecord::Migration[5.2]
  def change
    add_column :project_nodes, :approved, :boolean
  end
end
