namespace :odr do
  desc 'missing dataset for legacy data import'
  task datasets: :environment do
    initial = Dataset.count
    missing_datasets.each do |info_hash|
      org  = Organisation.find_by(name: info_hash[:organisation])
      raise 'no organisation found in db!' if org.nil?

      team = org.teams.find_by(name: info_hash[:team])
      raise 'no team found in db!' if team.nil?
    
      info_hash[:datasets].each do |name|
        dataset = Dataset.new(team: team, name: name, dataset_type: DatasetType.find_by(name: 'odr'))
        dataset.dataset_versions.build(semver_version: '1.0')
        dataset.save!
      end
    end
    print "created #{Dataset.count - initial} datasets\n"
  end

  task datasets_down: :environment do
    initial = Dataset.count
    Dataset.where(name: missing_datasets.flat_map { |h| h[:datasets] }).destroy_all
    print "destroyed #{initial - Dataset.count} datasets\n"
  end
  
  def missing_datasets
    [
      {
        organisation: 'Public Health England',
        team: 'NIS',
        datasets: [
          "NIS",
          "Salsurv (relating to salmonella infections)",
          "Verotoxigenic Escherichia coli (VTEC) variable number of tandem repeats (VNTR) database",
          "Local surveys of oral health among children and adults.",
          "National Enhanced Surveillance System for Verotoxigenic Escherichia coli (VTEC)", 
          "British Paediatric Surveillance Unit (BPSU) haemolytic uraemic syndrome (HUS) Surveillance",
          "DataMart Respiratory Viruses Laboratory Surveillance System"
        ]
      },
      {
        organisation: 'Public Health England',
        team: 'PHE Screening',
        datasets: ["Screening - Newborn and Infant Physical Examination"]
      },
      {
        organisation: 'Public Health England',
        team: 'NCRAS',
        datasets: ["Cancer Registration - QoL of Cancer Survivors (Breast, Colorectal, Prostate, Non-Hodgkin’s Lymphoma)"]
      }
      
      # TODO: don't know team
      # "Infectious Diseases in Pregnancy",
      # "NATSAL (National Survey of Sexual Attitudes and Lifestyles) 2010 sample linkage",
      
    ]
  end

  # these are on live but may be missing locally
  task create_teams_locally: :environment do
    org = Organisation.find_by(name: 'Public Health England')
    raise 'organisation not found!' if org.nil?

    initial = Team.count
    ['NIS', 'PHE Screening', 'NCRAS'].each do |name|
      org.teams.find_or_create_by!(name: name, z_team_status: ZTeamStatus.find_by(name: 'Active'))
    end
    print "#{Team.count - initial} teams created\n"
  end
end
