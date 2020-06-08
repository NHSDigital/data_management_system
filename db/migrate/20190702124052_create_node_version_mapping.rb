# Table for linking a node to another node
class CreateNodeVersionMapping < ActiveRecord::Migration[5.2]
  def change
    create_table :node_version_mappings do |t|
      t.integer :node_id
      t.integer :previous_node_id

      t.timestamps
    end
  end
end
