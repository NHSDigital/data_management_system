# TODO: dry up task now everything was built for the first time
namespace :xsd do
  task seed: :environment do
    print "\nDestroying existing non MBIS data\n"
    print "\nDestroying datasets\n"
    destroy_non_mbis_datasets

    print "\nDestroying metadata tables\n"
    existing = [DataDictionaryElement, ChoiceType, XmlType, XmlAttribute]
    existing.each(&:destroy_all)

    print "Seeding...\n"
    Rake::Task['xsd:xml_attributes'].invoke
    Rake::Task['xsd:datasets'].invoke
    Rake::Task['xsd:dataset_versions'].invoke
    Rake::Task['xsd:xml_types'].invoke
    Rake::Task['xsd:choice_types'].invoke
    Rake::Task['xsd:categories'].invoke
    Rake::Task['xsd:data_dictionary'].invoke
    Rake::Task['xsd:nodes'].invoke
    print "Done.\n"
  end

  # faster than destroying through assocations
  def destroy_non_mbis_datasets
    datasets = %w[COSD COSDPathology COSD_Pathology SACT MultipleRecordTypeDataset]
    Dataset.where(name: datasets).each do |dataset|
      DatasetVersion.transaction do
        dataset.dataset_versions.each do |dv|
          EnumerationValueDatasetVersion.where(dataset_version_id: dv.id).delete_all
          NodeCategory.where(node_id: dv.nodes.pluck(:id)).delete_all
          NodeVersionMapping.where(node_id: dv.nodes.pluck(:id)).delete_all
          NodeVersionMapping.where(previous_node_id: dv.nodes.pluck(:id)).delete_all
          Node.where(dataset_version_id: dv.id).delete_all
          Category.where(dataset_version_id: dv.id).delete_all
          dv.delete
        end
      end
      dataset.delete
    end
  end

  task nodes: :environment do
    fname = Rails.root.join('lib', 'tasks', 'xsd', 'nodes.yml')

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

  def build_child(node, row, version)
    child_node = build_node(row, version)
    node.child_nodes << child_node
    return if row['children'].blank?

    row['children'].each do |child|
      build_child(child_node, child, version)
    end
  end

  DIRECT_ATTRS = %w[name min_occurs max_occurs sort annotation reference description].freeze

  def build_node(row, version)
    options = DIRECT_ATTRS.each_with_object({}) { |v, h| h[v] = row[v] }
    options[:choice_type] = ChoiceType.find_by(name: row['choice_type']) if
      row['node_type'] == 'Nodes::Choice'
    options[:categories] = Category.where(name: row['categories'], dataset_version: version)
    add_data_dictionary_element(options, row) if row['node_type'] == 'Nodes::DataItem'
    add_xml_type(options, row) if row['node_type'] == 'Nodes::DataItem'
    options['annotation'] = 'TEMP ANNOTATION' if options['annotation'].nil?
    options['description'] = options['annotation'] if
      options['description'].nil? && row['node_type'] == 'Nodes::DataItem'
    row['node_type'].constantize.new(options.merge(dataset_version: version))
  end

  def add_data_dictionary_element(options, row)
    dde_options = row['data_dictionary_element']
    return if dde_options.blank?

    options[:data_dictionary_element] =
      DataDictionaryElement.find_by(name: dde_options['name'], group: dde_options['group'])
  end

  def add_xml_type(options, row)
    return if row['xml_type'].blank?

    options[:xml_type] = XmlType.find_by(name: row['xml_type'])
  end

  task xml_types: :environment do
    fname = Rails.root.join('lib', 'tasks', 'xsd', 'xml_types.yml')
    before = XmlType.count
    XmlType.transaction do
      YAML.safe_load(File.open(fname), [Symbol]).each do |row|
        row.delete(:pattern) if row[:pattern].blank?
        row.delete(:decimal_places) if row[:decimal_places].blank?
        ignore = %w[xml_attribute_for_value enumeration_values attribute_names]
        x = XmlType.new(row.except(*ignore))
        x.xml_attribute_for_value = XmlAttribute.find_by(name: row['xml_attribute_for_value'])
        add_enumeration_values(x, row['enumeration_values']) unless row['enumeration_values'].nil?
        add_xml_attributes(x, row['attribute_names']) unless row['attribute_names'].nil?
        x.save!
      rescue StandardError => e
        raise e
      end
    end
    print "Created #{XmlType.count - before} xml_type(s)\n\n"
  end

  def add_enumeration_values(xmltype_new, values)
    xmltype_new.enumeration_values = values.map do |v|
      ev = EnumerationValue.new(enumeration_value: v['enumeration_value'],
                                annotation: v['annotation'], sort: v['sort'])
      if v&.[]('datasets')
        v['datasets'].each_key do |ds|
          Dataset.find_by(name: ds).dataset_versions.each do |ver|
            ev.dataset_versions << ver if v['datasets'][ds].include? ver.semver_version
          end
        end
      end
      ev
    end
  end

  def add_xml_attributes(xmltype_new, values)
    xmltype_new.xml_attributes = values.map { |a_n| XmlAttribute.find_by(a_n) }
  end

  task datasets: :environment do
    fname = Rails.root.join('lib', 'tasks', 'xsd', 'datasets.yml')
    before = Dataset.count
    Dataset.transaction do
      YAML.safe_load(File.open(fname), [Symbol]).each_value do |row|
        d = Dataset.new(row)
        d.dataset_type = DatasetType.find_by(name: 'XML Schema')
        d.save!(validate: false)
      rescue StandardError => e
        raise e
      end
    end
    print "Created #{Dataset.count - before} dataset(s)\n\n"
  end

  task dataset_versions: :environment do
    fname = Rails.root.join('lib', 'tasks', 'xsd', 'dataset_versions.yml')
    before = DatasetVersion.count
    DatasetVersion.transaction do
      YAML.safe_load(File.open(fname), [Symbol]).each_value do |row|
        d = DatasetVersion.new(row.except('dataset'))
        d.dataset = Dataset.find_by(name: row['dataset'])
        d.save!
      rescue StandardError => e
        raise e
      end
    end
    print "Created #{DatasetVersion.count - before} dataset version(s)\n\n"
  end

  task xml_attributes: :environment do
    attrs = Rails.root.join('lib', 'tasks', 'xsd', 'xml_attributes.yml')
    counter = 0
    Nodes::DataItem.transaction do
      YAML.safe_load(File.open(attrs), [Symbol]).each_value do |row|
        x = XmlAttribute.new(row)
        x.save!
        counter += 1
      rescue StandardError => e
        raise e
      end
    end
    print "Updated #{counter} items \n\n"
  end

  task categories: :environment do
    fname = Rails.root.join('lib', 'tasks', 'xsd', 'categories.yml')
    before = Category.count
    Category.transaction do
      YAML.safe_load(File.open(fname), [Symbol]).each_value do |row|
        ignored_fields = %w[dataset_name dataset_version]
        e = Category.new(row.except(*ignored_fields))
        e.dataset_version = version_for_dataset(row['dataset_name'], row['dataset_version'])
        e.save!
      rescue StandardError => e
        raise e
      end
    end
    print "Created #{Category.count - before} Categories\n\n"
  end

  task data_dictionary: :environment do
    fname = Rails.root.join('lib', 'tasks', 'xsd', 'data_dictionary_element.yml')
    before = DataDictionaryElement.count
    DataDictionaryElement.transaction do
      YAML.safe_load(File.open(fname), [Symbol]).each do |row|
        dde = DataDictionaryElement.new(row.except('xml_type'))
        dde.xml_type = XmlType.find_by(name: row['xml_type']) unless row['xml_type'].nil?
        dde.save!
      rescue StandardError => e
        raise e
      end
    end
    print "Created #{DataDictionaryElement.count - before} dictionary elements\n\n"
  end

  task add_xml_type_to_data_dictionary: :environment do
    dde_attrs['xml_type'] = XmlType.find(dde.xml_type_id).name if dde.xml_type_id.present?
  end

  task choice_types: :environment do
    fname = Rails.root.join('lib', 'tasks', 'xsd', 'choice_types.csv')
    attrs = %w[name]
    before = ChoiceType.count
    CSV.open(fname).each_with_index do |line, i|
      next if i.zero?

      ChoiceType.create!(Hash[attrs.zip(line)])
    end
    print "Created #{ChoiceType.count - before} Choice Types\n\n"
  end

  def version_for_dataset(dataset, version)
    dv = Dataset.find_by(name: dataset).dataset_versions
    dv.find { |v| v.semver_version == version }
  end

  # Task for updating fixtures
  task upp: :environment do
    fname = Rails.root.join('lib', 'tasks', 'xsd', 'nodes.yml')
    x = YAML.safe_load(File.open(fname), [Symbol]).each do |row|
      child_up(row)
    end
    puts x.to_yaml
  end

  def child_up(node)
    node['xml_type'] = 'ST_PHE_YesNoNotApplicable' if ddates.include? node['name']
    return if node['children'].nil?

    node['children'].each do |child|
      child_up(child)
    end
  end

  def ddates
    %w[OrganConfinedInd TumourInvIndReteTestis TumourInvIndSeminalVesicles]
  end

  task add_data_dictionary_to_existing_items: :environment do
    groups = ['Breast', 'CTYA', 'Central Nervous System', 'Colorectal', 'Core', 'Gynaecological',
              'Haematological', 'Head and Neck', 'Liver', 'Lung', 'Sarcoma', 'Skin',
              'Upper Gastrointestinal', 'Urological']
    Dataset.find_by(name: 'COSD').dataset_versions.each do |dv|
      dv.data_items.each_with_index do |di, i|
        dde = DataDictionaryElement.where(group: groups).find_by(name: di.annotation)
        di.update_attribute(:data_dictionary_element, dde)
        print "\r #{i + 1}"
      end
    end
    Dataset.find_by(name: 'COSD_Pathology').dataset_versions.each do |dv|
      dv.data_items.each_with_index do |di, i|
        dde = DataDictionaryElement.where(group: 'Pathology').find_by(name: di.annotation)
        di.update_attribute(:data_dictionary_element, dde)
        print "\r #{i + 1}"
      end
    end
  end

  desc 'use to rebuild nodes.yml if making corrections on a local db'
  task export_db_nodes_to_yaml: :environment do
    Dataset.where(name: %w[COSD COSD_Pathology SACT MultipleRecordTypeDataset]).each do |dataset|
      dataset.dataset_versions.each do |dv|
        next unless dv.semver_version == '8-2' && dataset.name == 'COSD'

        # next if dv.semver_version == '9-0' && dataset.name == 'COSD'
        # next if dv.semver_version == '8-2' && dataset.name == 'COSD'
        # next if dv.semver_version == '4-0' && dataset.name == 'COSD_Pathology'
        # next if dv.semver_version == '3-0' && dataset.name == 'COSD_Pathology'
        puts "#{dataset.name} #{dv.semver_version}"
        version_nodes = dv.version_entity.child_nodes.sort_by(&:sort).map do |child_node|
          node_attrs(child_node)
        end
        filename = "#{dataset.name}_#{dv.semver_version}.yml"
        File.open(Rails.root.join('tmp', 'fixtures', filename), 'w') do |f|
          f.write(version_nodes.to_yaml)
        end
      end
    end
  end

  COMMON = %w[name min_occurs max_occurs type sort reference annotation description].freeze

  def node_attrs(child_node)
    attrs = COMMON.each_with_object({}) do |c, r|
      next if child_node.send(c).nil?

      r[c] = child_node.send(c)
    end
    attrs['categories'] = child_node.categories.map(&:name) if child_node.categories.present?
    attrs['choice_type'] = ChoiceType.find(child_node.choice_type_id).name if
      child_node.choice_type_id.present?
    attrs['node_type'] = attrs.delete('type')
    if child_node.child_nodes.present?
      attrs['children'] = child_node.child_nodes.sort_by(&:sort).map do |cn|
        node_attrs(cn)
      end
    end
    if attrs['node_type'] == 'Nodes::DataItem'
      if child_node.data_dictionary_element_id.present?
        dde = DataDictionaryElement.find(child_node.data_dictionary_element_id)
        dde_attrs = { 'name' => dde.name, 'group' => dde.group }
        attrs['data_dictionary_element'] = dde_attrs
      else
        attrs['xml_type'] = child_node.xml_type.name
      end
    end
    attrs
  end

  task data_dictionary_element_with_xml_type_to_yaml: :environment do
    ignore = %w[id created_at updated_at xml_type_id]
    dde_attrs = DataDictionaryElement.all.map do |dde|
      attrs = dde.attributes.except(*ignore)
      attrs['xml_type'] = XmlType.find(dde.xml_type_id).name if dde.xml_type_id.present?
      attrs.reject { |_, v| v.blank? }
    end
    filename = 'data_dictionary_element.yml'
    File.open(Rails.root.join('private', 'h_drive', filename), 'w') do |f|
      f.write(dde_attrs.to_yaml)
    end
  end

  desc 'add a reference to previous dataset version for a node if applicable'
  task previous_node_ids: :environment do
    fpath = Rails.root.join('lib', 'tasks', 'xsd', 'node_version_mappings.yml')
    lookup = YAML.load_file(fpath)
    counter = 0
    NodeVersionMapping.transaction do
      lookup.each do |maps|
        dataset = Dataset.find_by(name: maps['dataset'])
        current_version =
          dataset.dataset_versions.find_by(semver_version: maps['semver_version_current'])
        previous_version =
          dataset.dataset_versions.find_by(semver_version: maps['semver_version_to_diff'])
        current_version.nodes.each do |node|
          next if node.name == dataset.name # master parent

          previous_node_id = previous_version_node_id(node.xsd_element_name, node.parent_node&.name,
                                                      maps['mappings'], previous_version)
          next if previous_node_id.nil?

          counter += 1
          NodeVersionMapping.create!(node_id: node.id, previous_node_id: previous_node_id)
        end
      end
    end

    print "UPDATED #{counter} NODES\n"
  end

  task path_4_1_1_categories: :environment do
    fname = Rails.root.join('lib', 'tasks', 'xsd', 'categories.yml')
    before = Category.count
    Category.transaction do
      YAML.safe_load(File.open(fname), [Symbol]).each_value do |row|
        next unless row['dataset_version'] == '4-1-1'

        ignored_fields = %w[dataset_name dataset_version]
        e = Category.new(row.except(*ignored_fields))
        e.dataset_version = version_for_dataset(row['dataset_name'], row['dataset_version'])
        e.save!
      rescue StandardError => e
        raise e
      end
    end
    print "Created #{Category.count - before} Categories\n\n"
  end


  task path_4_1_1_nodes: :environment do
    fname = Rails.root.join('lib', 'tasks', 'xsd', 'nodes.yml')

    Node.transaction do
      YAML.safe_load(File.open(fname), [Symbol]).each do |row|
        version = row['dataset_version']
        next unless version == '4-1-1'

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

  def previous_version_node_id(xsd_element_name, parent_name, lookup, previous_version)
    results = lookup.find_all do |l|
      l['xsd_element_name_current'] == xsd_element_name && l['parent_current'] == parent_name
    end
    return if results.blank?

    raise "more than one value found! #{results.first}" if results.length > 1

    results = results.first
    previous = previous_version.nodes.find_all do |n|
      n.xsd_element_name == results['xsd_element_name_original'] &&
        n.parent_node&.name == results['parent_original']
    end
    return if previous.blank?

    raise 'more than one previous node found!' if previous.length > 1

    previous.first.id
  end
end
