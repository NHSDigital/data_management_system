class RenameTeamMembersToTeamMemberships < ActiveRecord::Migration[5.0]
  def change
    rename_table :team_members, :team_memberships
  end
end
