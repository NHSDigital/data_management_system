class AddCategoryIdToNode < ActiveRecord::Migration[5.2]
  def change
    add_column :nodes, :category_id, :integer
  end
end
