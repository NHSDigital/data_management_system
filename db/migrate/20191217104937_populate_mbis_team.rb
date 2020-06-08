class PopulateMbisTeam < ActiveRecord::Migration[6.0]
  def up
    return if Rails.env.test?
    return if Team.find_by(name: 'MBIS').present?

    mbis_team = Team.new(name: 'MBIS')
    mbis_team.division = Division.find_by(name: 'Knowledge & Intelligence')
    mbis_team.directorate = Division.find_by(name: 'Knowledge & Intelligence').directorate
    mbis_team.organisation = Organisation.find_by(name: 'Public Health England')
    mbis_team.location = 'London'
    mbis_team.z_team_status = ZTeamStatus.find_by(name: 'Active')

    mbis_team.save!
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
