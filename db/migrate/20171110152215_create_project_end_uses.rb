class CreateProjectEndUses < ActiveRecord::Migration[5.0]
  def change
    create_table :project_end_uses do |t|
      t.references :project, foreign_key: true
      t.references :end_use, foreign_key: true

      t.timestamps
    end
  end
end
