namespace :xsd do
  task to_yaml: :environment do
    datasets = {}
    versions = {}
    nodes = {}
    node_categories = {}
    version_categories = {}

    Dataset.all.each do |dataset|
      next unless versions_to_build.keys.include? dataset.name

      # dataset fixtures
      datasets.store(dataset.id, present_attributes(dataset))
      dataset.dataset_versions.each do |version|
        next unless versions_to_build[dataset.name].include? version.semver_version

        # version fixtures
        versions.store(version.id, present_attributes(version))
        # category fixtures
        version.categories&.each do |category|
          version_categories.store(category.id, present_attributes(category))
        end

        # node fixtures
        version.nodes.each do |node|
          nodes.store(node.id, present_attributes(node))
          node.node_categories&.each do |node_category|
            node_categories.store(node_category.id, present_attributes(node_category))
          end
        end
      end
    end

    save_fixture_file('node.yml', nodes)
    save_fixture_file('node_category.yml', node_categories)
    save_fixture_file('dataset.yml', datasets.sort.to_h)
    save_fixture_file('dataset_version.yml', versions.sort.to_h)

    [DataDictionaryElement, EnumerationValue, EnumerationValueDatasetVersion, Category,
     XmlType, XmlAttribute, XmlTypeXmlAttribute, ChoiceType, NodeVersionMapping].each do |klass|
       klass_to_fixtures(klass)
     end
  end

  def klass_to_fixtures(klass)
    fixtures = klass.all.each_with_object({}) do |instance, records|
      records.store instance.id, present_attributes(instance)
    end
    filename = "#{klass.model_name.element}.yml"
    save_fixture_file(filename, fixtures)
  end

  private

  def present_attributes(klass)
    klass.attributes.reject { |_, v| v.nil? }
  end

  def versions_to_build
    {
      'COSD'                      => %w[8-1 8-2 8-3 9-0],
      'COSD_Pathology'            => %w[3-0 3-1 4-1],
      'SACT'                      => %w[2-0],
      'MultipleRecordTypeDataset' => %w[1-0],
      'Births Gold Standard'      => %w[1-0],
      'Death Transaction'         => %w[1-0],
      'Deaths Gold Standard'      => %w[1-0],
      'Birth Transaction'         => %w[1-0]
    }
  end

  def save_fixture_file(filename, fixture)
    File.open(Rails.root.join('tmp', 'fixtures', filename), 'w') do |f|
      f.write(YAML.dump(fixture).to_s)
    end
  end
end
