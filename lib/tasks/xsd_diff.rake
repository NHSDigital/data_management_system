namespace :xsd do
  desc 'Diff two versions of the same schema'
  task diff: :environment do
    require 'rainbow'

    print "\nDataset available in DB: #{Dataset.all.map(&:name).join(', ')}\n"
    name     = ask('Dataset Name (blank to default to COSD): ').presence || 'COSD'
    dataset  = Dataset.find_by!(name: name)
    versions = dataset.dataset_versions.map(&:semver_version)

    print "\nVersions available in DB for this dataset: #{versions.join(', ')}\n"
    version1 = ask('First version?')
    version2 = ask('Second version?')

    v1 = dataset.dataset_versions.find_by!(semver_version: version1)
    v2 = dataset.dataset_versions.find_by!(semver_version: version2)

    nd = Nodes::Diff.new(v1.version_entity, v2.version_entity, v1)

    def print_node_diffs(diffs, buffer = [], depth = 0)
      diffs.each do |diff|
        # colour = { '+' => 'green', '-' => 'red', '=' => 'white', '|' => 'yellow' }[diff.symbol]

        case diff.symbol
        when '+'
          buffer << Rainbow("+#{' ' * (depth * 2)}#{diff.new_node.xsd_element_name}").green
        when '-'
          buffer << Rainbow("-#{' ' * (depth * 2)}#{diff.old_node.xsd_element_name}").red
        when '|'
          # Currently the old and new names are always the same, because that's
          # the key used to define identity. However, this could change.
          buffer << Rainbow("±#{' ' * (depth * 2)}#{diff.old_node.xsd_element_name} -> " \
                            "#{diff.new_node.xsd_element_name} #{diff.changed_keys}").yellow
        when '='
          buffer << Rainbow(" #{' ' * (depth * 2)}#{diff.old_node.xsd_element_name}")
        end

        print_node_diffs(diff.child_nodes, buffer, depth + 1)
      end

      buffer
    end

    puts
    puts
    puts print_node_diffs([nd])
  end

  PRINT_XML_FIELDS = %w[xml_type].freeze

  task temp_change_log: %i[seed previous_node_ids]

  XML_TYPE_IGNORED_FIELDS = %w[id created_at updated_at namespace_id annotation
                               xml_attribute_for_value_id].freeze

  desc 'v9 and v4 change logs'
  task change_log: :environment do
    require 'rainbow'
    @category_mode = true if ENV['CAT_MODE']
    @simplified    = true if ENV['OUTPUT']

    if ENV['DATASET'] == 'COSD'
      dataset = Dataset.find_by!(name: 'COSD')
      v1 = dataset.dataset_versions.find_by!(semver_version: '8-1')
      v2 = dataset.dataset_versions.find_by!(semver_version: '9-0')
    else
      dataset = Dataset.find_by!(name: 'COSD_Pathology')
      v1 = dataset.dataset_versions.find_by!(semver_version: '3-0')
      v2 = dataset.dataset_versions.find_by!(semver_version: '4-0')
    end


    print "SCHEMA DETAILS\n\n"
    change_log = Nodes::ChangeLog.new(v1.version_entity, v2.version_entity, v1)
    save_file(change_log.txt, "#{Date.current.strftime('&Y%m%d')}_change_log.txt")
  end

  def save_file(output, filename)
    File.open(Rails.root.join('tmp', 'change_logs', filename), 'w') do |f|
      f.write(output)
    end
  end
end
