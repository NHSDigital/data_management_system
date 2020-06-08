class CreateProjectTypes < ActiveRecord::Migration[5.2]
  def change
    create_table :project_types do |t|
      t.string :value
      t.timestamps
    end
  end
end
