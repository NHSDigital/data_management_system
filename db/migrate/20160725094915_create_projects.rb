class CreateProjects < ActiveRecord::Migration[5.0]
  def change
    create_table :projects do |t|
      t.string :name
      t.text :description
      t.references :z_project_status, foreign_key: true
      t.date :start_data_date
      t.date :end_data_date
      t.references :team, foreign_key: true
      t.text :how_data_will_be_used
      t.string :head_of_profession
      t.integer :senior_user_id
      t.string :data_access_address
      t.string :data_access_postcode

      t.timestamps
    end
  end
end
