class CreateSystemRole < ActiveRecord::Migration[6.0]
  def change
    create_table :system_roles do |t|
      t.string :name
      t.datetime :startdate
      t.datetime :enddate
      t.integer :sort
    
      t.timestamps
    end
  end
end
