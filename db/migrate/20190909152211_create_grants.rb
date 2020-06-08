class CreateGrants < ActiveRecord::Migration[6.0]
  def change
    create_table :grants do |t|
      t.integer :user_id, null: false
      t.references :roleable, polymorphic: true


      t.integer :team_id
      t.integer :project_id

      t.timestamps
    end

    # add_foreign_key :grants, :roles
    add_foreign_key :grants, :users
  end
end
