class CreateProjectDataTeamMemberships < ActiveRecord::Migration[5.0]
  def change
    create_table :project_data_team_memberships do |t|
      t.references :project, foreign_key: true
      t.references :team_membership, foreign_key: true

      t.timestamps
    end
  end
end
