class AddDerivedToNode < ActiveRecord::Migration[6.0]
  def change
    add_column :nodes, :derived, :boolean
  end
end
