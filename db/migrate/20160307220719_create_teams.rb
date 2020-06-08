class CreateTeams < ActiveRecord::Migration[5.0]
  def change
    create_table :teams do |t|
      t.string :name
      t.string :location
      t.string :postcode
      t.integer :zteamstatus_id
      t.string :telephone
      t.string :notes

      t.timestamps null: false
    end
  end
end
