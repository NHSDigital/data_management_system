class AddGovernanceIdToNode < ActiveRecord::Migration[5.2]
  def change
    add_column :nodes, :governance_id, :integer
  end
end
