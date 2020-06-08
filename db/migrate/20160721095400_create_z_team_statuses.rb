class CreateZTeamStatuses < ActiveRecord::Migration[5.0]
  def change
    create_table :z_team_statuses do |t|
      t.string :name

      t.timestamps
    end
  end
end
