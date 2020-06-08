class CreateProjectOutputs < ActiveRecord::Migration[5.0]
  def change
    create_table :project_outputs do |t|
      t.references :project, foreign_key: true
      t.references :output, foreign_key: true      

      t.timestamps
    end
  end
end
