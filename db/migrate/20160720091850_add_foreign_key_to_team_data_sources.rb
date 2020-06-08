class AddForeignKeyToTeamDataSources < ActiveRecord::Migration[5.0]
  def change
    add_foreign_key :team_data_sources, :teams
    add_foreign_key :team_data_sources, :data_sources
  end
end
