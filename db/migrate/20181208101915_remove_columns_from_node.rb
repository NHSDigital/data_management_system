class RemoveColumnsFromNode < ActiveRecord::Migration[5.2]
  def change
    remove_column :nodes, :node_id, :integer
    remove_column :nodes, :group_id, :integer
    remove_column :nodes, :node_choice_id, :integer
    remove_column :nodes, :choice_node_id, :integer
  end
end
