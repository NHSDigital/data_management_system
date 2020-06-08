# Task to get some real sample EOI data in
# When something is eventually final use a migration

namespace :eoi_import do
  task all: %i[orgs_and_teams users sample_data]

  task orgs_and_teams: :environment do
    new_dataset = OdrDataImporter::Base.new('20191115_organisations_and_teams.xlsx')
    new_dataset.import_organisations_and_teams!
  end

  task users: :environment do
    importer = OdrDataImporter::Base.new('20191115 List of application managers.xlsx')
    importer.build_application_managers!

    importer = OdrDataImporter::Base.new('20191115_SampleEOIData.xlsx', 'SeniorUsers')
    importer.import_users_for_eois!
  end

  task sample_data: :environment do
    importer = OdrDataImporter::Base.new('20191115_SampleEOIData.xlsx', 'EOI_Detail')
    importer.import_eois!
  end
end
