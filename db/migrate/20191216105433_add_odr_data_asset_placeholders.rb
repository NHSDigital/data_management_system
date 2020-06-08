class AddOdrDataAssetPlaceholders < ActiveRecord::Migration[6.0]
  def up
    return if Rails.env.test?

    data_assets.each do |team_name, assets|
      team = create_team(team_name)
      assets.each do |asset_name, description|
        dataset = Dataset.find_by(name: asset_name)
        next if dataset.present?

        new_asset = Dataset.new(name: asset_name, description: description)
        new_asset.team = team
        new_asset.dataset_type = DatasetType.find_by(name: 'odr')
        dataset_version = DatasetVersion.new(semver_version: '4-0', published: true)
        dataset_version.nodes << Nodes::Entity.new(name: asset_name, min_occurs: 1, max_occurs: 1,
                                                   description: asset_name)
        new_asset.dataset_versions << dataset_version

        new_asset.save!
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  def create_team(name)
    team = Team.find_by(name: name)
    return team if team

    organisation = Organisation.find_by(name: 'Public Health England')
    Team.create!(organisation: organisation, name: name, location: 'London',
                 z_team_status_id: ZTeamStatus.find_by(name: 'Active').id)
  end

  def data_assets
    {
      'NCRAS' => {
        'BCCOM'  => 'Breast Cancer Clinical Outcome Measures',
        'DAHNO'  => 'National Head and Neck Cancer Audit',
        'NPCA'   => 'National Prostate Cancer Audit',
        'NBOCAP' => 'National Bowel Cancer Audit',
        'Routes to Diagnosis' => 'Routes to Diagnosis',
        'ONS Mortality' => 'ONS Mortality',
        'NCAPOP' => 'National Clinical Audit and Patient Outcomes Programme'
      },
      'NDTMS' => {
        'NDTMS' => 'National Drug Treatment Monitoring System'
      },
      'HCAI & AMR' => {
        'Health Care Acquired Infections (HCAI) Data System' => 'Health Care Acquired Infections (HCAI) Data System',        
      },
      'PHE Screening' => {
        'Screening Programme - AAA'                         => 'Screening Programme - AAA',
        'Screening Programme - Bowel'                       => 'Screening Programme - Bowel',
        'Screening Programme - Breast'                      => 'Screening Programme - Breast',
        'Screening Programme - Cervical'                    => 'Screening Programme - Cervical',
        'Screening Programme - Diabetic Retinopathy'        => 'Screening Programme - Diabetic Retinopathy',
        'Screening Programme - Newborn Hearing'             => 'Screening Programme - Newborn Hearing',
        'Screening Programme - SLOANE Audit'                => 'Screening Programme - SLOANE Audit',
        'Screening Programme - Sickle Cell and Thalassamia' => 'Screening Programme - Sickle Cell and Thalassamia',
        'Screening Programme - Newborn Blood Spot'          => 'Screening Programme - Newborn Blood Spot',
        'Screening Programme - Fetal Anonaly'               => 'Screening Programme - Fetal Anonaly'
      },
      'TARGET' => {
        'Respiratory Department/Epidemiology Teams' => 'Respiratory Department/Epidemiology Teams',
        'Pandemic Flu' => 'Pandemic Flu',
        'Malaria database' => 'Malaria database'
      },
      'NCARDS' => {
         'Congential anomalies' => 'Congential anomalies'
      }
    } 
  end
end
