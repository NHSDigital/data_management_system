namespace :xsd do
  namespace :browser do
    task build: :environment do
      print "\nDataset available in DB: #{Dataset.all.map(&:name).join(', ')}\n"
      name     = ask('Dataset Name (blank to default to COSD): ').presence || 'COSD'
      dataset  = Dataset.find_by!(name: name)
      versions = dataset.dataset_versions.map(&:semver_version)

      print "\nVersions available in DB for this dataset: #{versions.join(', ')}\n"
      version2 = ask('Later version?')
      version1 = ask('Previous version?')

      dv1 = version1.blank? ? nil : dataset.dataset_versions.find_by!(semver_version: version1)
      dv2 = dataset.dataset_versions.find_by!(semver_version: version2)

      print "Generating...\n"
      browser = SchemaBrowser::Builder.new(dataset, dv2, dv1)
      print "Saving...\n"
      browser.components.each(&:save_file)
      print "Done\n"
    end

    desc 'v9 and v4 schema browsers with change logs'
    task latest: :environment do
      dataset = Dataset.find_by(name: ENV['DATASET'] == 'COSD' ? 'COSD' : 'COSD_Pathology')
      v = ENV['DATASET'] == 'COSD' ? '9-0' : '4-0'
      version = dataset.dataset_versions.find_by(semver_version: v)

      # For Change Log
      v = ENV['DATASET'] == 'COSD' ? '8-1' : '3-0'
      version_previous = dataset.dataset_versions.find_by(semver_version: v)
      print "Generating...\n"
      browser = SchemaBrowser::Builder.new(dataset, version, version_previous)
      print "Saving...\n"
      browser.components.each(&:save_file)
      print "Done\n"
    end
  end
end
