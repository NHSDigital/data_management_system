class AddZTeamStatusToTeams < ActiveRecord::Migration[5.0]
  def change
    remove_column :teams, :status
    rename_column :teams, :zteamstatus_id, :z_team_status_id
  end
end
