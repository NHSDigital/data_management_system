class AddDescriptionDetailToNode < ActiveRecord::Migration[6.0]
  def change
    add_column :nodes, :description_detail, :text
  end
end
