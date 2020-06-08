class RenameProjectDataTeamMembershipsTableToProjectTeamMemberships < ActiveRecord::Migration[5.0]
  def change
    rename_table :project_data_team_memberships, :project_team_memberships
  end
end
