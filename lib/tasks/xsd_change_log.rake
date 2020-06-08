namespace :xsd do
  namespace :change_log do
    # local testing - reseed database and build change log
    task temp_change_log: %i[seed previous_node_ids latest]

    task build: :environment do
      require 'rainbow'
      print_output = true if ENV['OUTPUT']
      print "\nDataset available in DB: #{Dataset.all.map(&:name).join(', ')}\n"
      name     = ask('Dataset Name (blank to default to COSD): ').presence || 'COSD'
      dataset  = Dataset.find_by!(name: name)
      versions = dataset.dataset_versions.map(&:semver_version)

      print "\nVersions available in DB for this dataset: #{versions.join(', ')}\n"
      version2 = ask('Later version?')
      version1 = ask('Previous version?')

      dv1 = dataset.dataset_versions.find_by!(semver_version: version1)
      dv2 = dataset.dataset_versions.find_by!(semver_version: version2)

      build_diff(dataset, dv1, dv2, print_output)
    end

    desc 'v9 and v4 change logs'
    task latest: :environment do
      require 'rainbow'
      print_output = true if ENV['OUTPUT']

      if ENV['DATASET'] == 'COSD'
        dataset = Dataset.find_by!(name: 'COSD')
        dv1 = dataset.dataset_versions.find_by!(semver_version: '8-1')
        dv2 = dataset.dataset_versions.find_by!(semver_version: '9-0')
      else
        dataset = Dataset.find_by!(name: 'COSD_Pathology')
        dv1 = dataset.dataset_versions.find_by!(semver_version: '3-0')
        dv2 = dataset.dataset_versions.find_by!(semver_version: '4-0')
      end
      build_diff(dataset, dv1, dv2, print_output)
    end

    def build_diff(dataset, dv1, dv2, print_output)
      change_log = Nodes::ChangeLog.new(dataset, dv1, dv2, print_output)
      change_log.save_file
    end
  end
end
