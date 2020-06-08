class CreateDivisions < ActiveRecord::Migration[5.0]
  def change
    create_table :divisions do |t|
      t.integer :directorate_id
      t.string :name
      t.string :head_of_profession

      t.timestamps
    end
  end
end
