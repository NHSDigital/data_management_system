namespace :import do
  task odr_spreadsheet: :environment do
    # Update organisations
    update_orgs = OdrDataImporter::Base.new(ENV['application_fname'], 'Orgs - name update')
    update_orgs.update_organisation_names

    # Import new organisations
    import_orgs = OdrDataImporter::Base.new(ENV['application_fname'], 'Orgs - New')
    import_orgs.import_organisations

    # Import Teams
    import_teams = OdrDataImporter::Base.new(ENV['application_fname'], 'Teams')
    import_teams.import_teams

    # Import Users
    import_users = OdrDataImporter::Base.new(ENV['application_fname'], 'Users')
    import_users.import_users

    # Import Applications
    import_applications = OdrDataImporter::Base.new(ENV['application_fname'], 'Applications')
    import_applications.import_applications

    # Import Amendments
    import_amendments = OdrDataImporter::Base.new(ENV['amendments_fname'], 'Amendments')
    import_amendments.import_amendments

    # Import DPIA's
    import_dpias = OdrDataImporter::Base.new(ENV['dpias_fname'], 'DPIA_data for migration')
    import_dpias.import_dpias
  end
end
