class ChangeNodeMinMaxOccurs < ActiveRecord::Migration[5.2]
  def change
    remove_column :nodes, :min_occurs, :string
    remove_column :nodes, :max_occurs, :string
    add_column :nodes, :min_occurs, :integer
    add_column :nodes, :max_occurs, :integer
  end
end
