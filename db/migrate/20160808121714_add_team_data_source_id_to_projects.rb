class AddTeamDataSourceIdToProjects < ActiveRecord::Migration[5.0]
  def change
    add_column :projects, :team_data_source_id, :integer
  end
end
