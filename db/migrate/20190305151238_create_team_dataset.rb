class CreateTeamDataset < ActiveRecord::Migration[5.2]
  def change
    create_table :team_datasets do |t|
      t.integer   :team_id
      t.integer   :dataset_id
      t.timestamps
    end
  end
end
