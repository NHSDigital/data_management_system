class PopulateSloaneScreenDataset < ActiveRecord::Migration[6.0]
  def up
    return if Rails.env.test?

    data_file = Rails.root.join('db', 'files', '20200130_SampleEOIData_sample_kl.xlsx')
    return unless File.exists?(data_file)

    odr = OdrDataImporter::Base.new('20200130_SampleEOIData_sample_kl.xlsx', 'Address list')
    odr.import_organisations_and_teams!
    
    org = Organisation.where(name: 'UK National Screening Committee').first_or_create!
    team = Team.where(name: 'PHE Screening', organisation_id: org.id).first_or_create!

    dataset = Dataset.create!(name: 'Screening Programme - SLOANE',
                              dataset_type: DatasetType.find_by(name: 'odr'),
                              team: team)
    DatasetVersion.create!(semver_version: '2.1', dataset: dataset)
  end

  def down
    return if Rails.env.test?

    Dataset.find_by(name: 'Screening Programme - SLOANE').destroy
  end
end
