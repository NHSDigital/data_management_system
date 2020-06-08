class CreateProjectDataEndUsers < ActiveRecord::Migration[5.0]
  def change
    create_table :project_data_end_users do |t|
      t.integer :project_id
      t.string :first_name
      t.string :last_name
      t.string :email

      t.timestamps
    end
  end
end
