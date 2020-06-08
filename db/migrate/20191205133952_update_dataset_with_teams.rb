class UpdateDatasetWithTeams < ActiveRecord::Migration[6.0]
  def up
    return if Rails.env.test?

    Dataset.reset_column_information
    ZTeamStatus.find_or_create_by!(name: 'Active')
    phe =  Organisation.find_by(name: 'Public Health England')
    team_datasets.each do |team_name, team_data|
      directorate = Directorate.find_or_create_by!(name: team_data[:directorate], active: true)
      division = Division.find_or_create_by!(name: team_data[:division],
                                             directorate_id: directorate.id,
                                             active: true)
      team = Team.find_or_create_by!(name: team_name,
                                     directorate_id: directorate.id,
                                     division_id: division.id,
                                     organisation_id: phe.id,
                                     location: 'London',
                                     z_team_status_id: ZTeamStatus.find_by(name: 'Active').id)
      team_data[:datasets].each do |dataset|
        present_in_db = Dataset.find_by(name: dataset).presence
        next unless present_in_db

        present_in_db.update_attribute(:team_id, team.id)
      end                           
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  def team_datasets
    {
      'NCRAS' => {
        division: 'National Disease Registration & Cancer Analysis Service',
        directorate: 'Health Improvement',
        datasets: %w[COSD COSD_Pathology SACT]
      },
      'TEST' => {
        division: 'TEST',
        directorate: 'TEST',
        datasets: ['Birth Transaction', 'Births Gold Standard',
                   'Death Transaction', 'Deaths Gold Standard']
      },
      'ODR' => {
        division: 'Office for Data Release (ODR)',
        directorate: 'Health Improvement',
        datasets: ['Cancer Registry', 'Linked HES IP', 'Linked HES OP', 'Linked HES A&E']
      }
    }
  end
end
