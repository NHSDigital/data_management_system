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

    desc 'v8/v9 differences'
    task cosd_v8_v9_diffs_rawtext: :environment do
      filename = ENV['FILE']
      require 'csv'
      rows = []
      CSV.open(filename, "r+") do |csv|
        csv.each_with_index do |row, i|
          next if i == 0
          rows << [row[0], row[1], row[2], row[3], row[4], row[5], row[6]]
        end
        etype_row = []
        rows.each do |row|
          row_etype = EraFields.find_by(ebr_rawtext_name: row[4])&.ebr
          row_etype.nil? ? row_etype = '' : row_etype = row_etype[0]
          etype_row << [row[0], row[1], row[2], row[3], row[4], row[5], row_etype, row[6]]
        end

        csv = CSV.new('v8_v9_diffs_rawtext.csv')
        CSV.open('v8_v9_diffs_rawtext.csv', "wb") do |csv|
          csv << ["V8 only rawtext_name", "V8 only code", "V8 only fieldname", "Same item number?", "V9 only rawtext_name", "V9 only code", "V9 only record type", "Same item number?"]
          etype_row.each do |item|
            csv << [item[0], item[1], item[2], item[3], item[4], item[5], item[6], item[7]]
          end
        end
      end
    end

    def build_diff(dataset, dv1, dv2, print_output)
      change_log = Nodes::ChangeLog.new(dataset, dv1, dv2, print_output)
      change_log.save_file
    end
  end
end
