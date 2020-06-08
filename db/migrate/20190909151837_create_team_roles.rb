class CreateTeamRoles < ActiveRecord::Migration[6.0]
  def change
    create_table :team_roles do |t|
      t.string :name
      t.string :role_type
      t.datetime :startdate
      t.datetime :enddate
      t.integer :sort
      
      t.timestamps
    end
  end
end
