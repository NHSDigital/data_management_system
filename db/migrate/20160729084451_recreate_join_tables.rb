class RecreateJoinTables < ActiveRecord::Migration[5.0]
  def change
    drop_table :team_memberships, force: :cascade
    create_table :memberships do |t|
      t.references :team, foreign_key: true, null: false
      t.references :user, foreign_key: true, null: false
      t.string  :role 
      t.timestamps
    end

    add_index :memberships, [:user_id, :team_id], unique: true

    drop_table :project_team_memberships, force: :cascade
    create_table :project_memberships do |t|
      t.references :project,    foreign_key: true, null: false
      t.references :membership, foreign_key: true, null: false
      t.timestamps
    end

    add_index :project_memberships, [:project_id, :membership_id], unique: true
  end
end
