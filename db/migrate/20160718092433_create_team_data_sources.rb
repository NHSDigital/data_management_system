class CreateTeamDataSources < ActiveRecord::Migration[5.0]
  def change
    create_table :team_data_sources do |t|
      t.integer   :team_id
      t.integer   :data_source_id
      t.timestamps
    end
  end
end
