class CreateNodeCategory < ActiveRecord::Migration[5.2]
  def change
    create_table :node_categories do |t|
      t.references :node, foreign_key: true
      t.references :category, foreign_key: true

      t.timestamps
    end
  end
end
