class CreateProjectNode < ActiveRecord::Migration[5.2]
  def change
    create_table :project_nodes do |t|
      t.references :project, foreign_key: true
      t.references :node, foreign_key: true

      t.timestamps
    end
  end
end
