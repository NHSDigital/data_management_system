class AddRoleToTeamMember < ActiveRecord::Migration[5.0]
  def change
    add_column :team_members, :role, :string
  end
end
