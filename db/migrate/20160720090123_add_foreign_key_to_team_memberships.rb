class AddForeignKeyToTeamMemberships < ActiveRecord::Migration[5.0]
  def change
    add_foreign_key :team_memberships, :teams
    add_foreign_key :team_memberships, :users
  end
end
