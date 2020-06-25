class CorrectionOdrOrganisations < ActiveRecord::Migration[6.0]
  def up
    return if Rails.env.test?
    return if Organisation.where(name: 'Adelphi Group').present?

    data_file = Rails.root.join('db', 'files', '20200130_SampleEOIData_sample_kl.xlsx')
    return unless File.exists?(data_file)

    odr = OdrDataImporter::Base.new('20200130_SampleEOIData_sample_kl.xlsx', 'Address list')
    odr.import_organisations_and_teams!
  end

  def down
    # Do nothing
  end
end
