class AddTeamIdToDataset < ActiveRecord::Migration[6.0]
  def change
    add_column :datasets, :team_id, :integer
  end
end
