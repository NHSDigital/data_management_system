# TODO: dry up task now everything was built for the first time
namespace :cas do
  task seed: :environment do
    print "Destroying existing CAS dataset\n"
    dataset = Dataset.find_by(name: 'CAS')
    dataset&.destroy

    print "Seeding...\n"
    dataset = Dataset.new(name: 'CAS', description: 'Cancer Analysis System',
                          team: Team.find_by(name: 'NCRAS'),
                          dataset_type: DatasetType.fetch(:table_spec))
    dataset.dataset_versions << DatasetVersion.new(semver_version: '1-0', published: true)
    dataset.save!

    Rake::Task['cas:nodes'].invoke
    print "Done.\n"
  end

  # TODO: dry up with seed_xsd_tables.rake
  task nodes: :environment do
    fname = Rails.root.join('lib', 'tasks', 'xsd', 'nodes_cas.yml')

    Node.transaction do
      YAML.safe_load(File.open(fname), [Symbol]).each do |row|
        version = row['dataset_version']
        dataset = row['name']
        print "Building nodes for #{version}\n"
        version = version_for_dataset(dataset, version)
        node = build_node(row, version)
        if row['children'].present?
          row['children'].each do |child_row|
            build_child(node, child_row, version)
          end
        end
        node.save!
      end
    end
  end
end
