class AddContraintToTeamDataSources< ActiveRecord::Migration[5.0]
  def change
    add_index :team_data_sources, [:data_source_id, :team_id], unique: true
  end
end
