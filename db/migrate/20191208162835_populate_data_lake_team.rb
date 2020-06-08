class PopulateDataLakeTeam < ActiveRecord::Migration[6.0]
  def change
    return if Rails.env.test?
    return if Team.find_by(name: 'Data Lake').present?

    directorate = Directorate.find_or_create_by!(name: 'Health Improvement')
    Division.find_or_create_by!(name: 'Knowledge & Intelligence', directorate_id: directorate.id)
    data_lake_team = Team.new(name: 'Data Lake')
    data_lake_team.division = Division.find_by(name: 'Knowledge & Intelligence')
    data_lake_team.directorate = Division.find_by(name: 'Knowledge & Intelligence').directorate
    data_lake_team.organisation = Organisation.find_by(name: 'Public Health England')
    data_lake_team.location = 'London'
    data_lake_team.z_team_status = ZTeamStatus.find_by(name: 'Active')
    # TODO: description
    data_lake_team.save!
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
