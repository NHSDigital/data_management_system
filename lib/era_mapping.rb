# Produce a catch_all mapping for Encore
class EraMapping
  attr_accessor :version, :mappings

  def initialize(version)
    @version = version
    @mappings = {}
  end

  # NB if building a pathology mapping Encore requires a hidden mapping entry
  # ---
  # - column: dummy_mapping
  # ---
  # path_mapping
  def build
    version.immediate_child_entities_of_record.each do |record_entity|
      entity_nodes = []
      record_entity.child_nodes.each do |child_node|
        map_child_node(record_entity.name, child_node, entity_nodes)
      end
      mappings[record_entity.name] = entity_nodes
    end
  end

  def output
    filename = "#{Time.current.strftime('%Y%m%d')}_#{version.dataset.name}"
    filename += "_#{version.semver_version}.yml"
    file = Rails.root.join('tmp').join(filename)
    File.open(file, 'wb') do |f|
      f.write mappings.to_yaml
    end
  end

  def map_child_node(record_entity_name, node, array_of_nodes)
    array_of_nodes << build_mapping(record_entity_name, node) if node.data_item?
    return if node.child_nodes.blank?

    node.child_nodes.each do |child_node|
      map_child_node(record_entity_name, child_node, array_of_nodes)
    end
  end

  def build_mapping(record_entity_name, node)
    {
      'column' => node.xsd_element_name,
      'rawtext_name' => node.era_fields&.ebr_rawtext_name,
      'cosd_xml' => {
        'id' => node.reference,
        'relative_path' => relative_path(record_entity_name, node),
        'attribute' => attr_for(node),
        'version' => ">= #{version.semver_version.gsub('-', '.')}"
      },
      'mappings' => node.era_fields&.ebr_virtual_name&.map { |v| { 'field' => v } }
    }
  end

  def attr_for(node)
    return unless node&.xmltype&.xml_attributes&.present?

    # Mapping currently expects one xml_attribute and if present we will only have on attribute
    # BUT xml rules do allow multiple attributes for an element
    node.xmltype.xml_attributes.first.name
  end

  # if item's first parent is a record entity the relative path is nil
  # if item's first parent is not the record entity, then build up the relative path
  def relative_path(record_entity_name, node)
    return nil if node.parent_entity_in_tree&.name == record_entity_name

    build_relative_path(node, record_entity_name)
  end

  # build up path until we hit record_entity_name
  # TODO: building the wrong way around
  def build_relative_path(node, record_entity_name, relative_path = '')
    relative_path.prepend node.parent_entity_in_tree&.name
    relative_path.prepend '/'
    return relative_path if
      node.parent_entity_in_tree.parent_entity_in_tree.name == record_entity_name

    build_relative_path(node.parent_entity_in_tree, record_entity_name, relative_path)
  end
end
