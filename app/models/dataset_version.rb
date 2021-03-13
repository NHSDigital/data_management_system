# Version for a dataset
class DatasetVersion < ApplicationRecord
  include Xsd::XmlHeader

  has_many :nodes, class_name: 'Node', inverse_of: :dataset_version, dependent: :destroy
  # TODO: consider rewriting to hang these solely off the version_entity (which is part of the node tree)
  has_many :entities, class_name: 'Nodes::Entity', inverse_of: :dataset_version,
                      dependent: :destroy
  has_many :data_items, class_name: 'Nodes::DataItem', inverse_of: :dataset_version,
                        dependent: :destroy
  has_many :groups, class_name: 'Nodes::Group', inverse_of: :dataset_version,
                    dependent: :destroy
  has_many :categories, class_name: 'Category', inverse_of: :dataset_version,
                        dependent: :destroy
  accepts_nested_attributes_for :categories, reject_if: :all_blank, allow_destroy: true
  has_many :choices, class_name: 'Nodes::Choice', inverse_of: :dataset_version,
                     dependent: :destroy
  has_many :category_choices, class_name: 'Nodes::CategoryChoice', inverse_of: :dataset_version,
                              dependent: :destroy
  has_many :data_item_groups, class_name: 'Nodes::DataItemGroup', inverse_of: :dataset_version,
                              dependent: :destroy
  has_many :table_nodes, class_name: 'Nodes::Table', inverse_of: :dataset_version,
                         dependent: :destroy

  has_many :enumeration_value_dataset_versions, dependent: :destroy, inverse_of: :dataset_version
  has_many :enumeration_values, through: :enumeration_value_dataset_versions

  belongs_to :dataset

  # dataset_name
  delegate :name, to: :dataset

  delegate :preloaded_descendants, to: :version_entity

  validates :semver_version, uniqueness: { scope: :dataset,
                                           message: 'Version already exists for dataset!' }

  validate :ensure_only_one_core_category
  validate :ensure_core_category_present, on: :publish
  
  scope :published, -> { where(published: true) }
  scope :unpublished, -> { where(published: false) }

  before_destroy do
    throw(:abort) if in_use?
  end

  def in_use?
    ProjectNode.where(node_id: nodes.map(&:id)).count.positive?
  end

  # Not to file
  def to_xsd
    schema = ::Builder::XmlMarkup.new(target: '', indent: 2)
    schema.instruct!
    schema.xs :schema, ns('xs', :w3, :schema, false) do |schema_|
      version_entity_xsd(schema_)
      build_common(schema_)
      build_xsd_groups(schema_)
      build_xml_data_type_references(schema_)
    end
  end

  def header_nodes
    return if version_entity.nil?

    version_entity.child_nodes.data_items
  end

  # First entity in tree should be dataset.
  # e.g for COSD it would be a COSD entity with items for file header, then Record entity
  #     for SACT it would be a SACT entity with just a Record entity
  def version_entity_xsd(schema)
    # build differently with groups from Record entity down tree
    build_element(schema, :element, name: version_entity.name, type: version_entity.name)
    # Ignore entity's items, we'll build a xsd group of them later
    version_entity.build(schema)
  end

  def version_entity
    @version_entity ||= nodes.find_by(type: 'Nodes::Entity', name: name)
  end

  # Optimised set of entities, for "hot paths" of schema generation:
  def preloaded_entities
    @preloaded_entities ||= [version_entity] + preloaded_descendants.select(&:entity?)
  end

  # Optimised set of data items, for "hot paths" of schema generation:
  def preloaded_data_items
    @preloaded_data_items ||= preloaded_descendants.select(&:data_item?)
  end

  # Build all the common Complex Types. e.g LinkagePatientId
  def build_common(schema)
    preloaded_entities.each do |entity|
      entity.complex_entity(schema, true)
    end
  end

  # Build groups of items that out complexType entities reference
  def build_xsd_groups(schema)
    groups.each do |group|
      group.to_xsd_groups(schema)
    end
  end

  def build_xml_data_type_references(schema)
    preloaded_data_items.map(&:xmltype).uniq.each do |xml_type|
      next unless xml_type.build_xsd?

      xml_type.to_xsd(schema, self)
    end
  end

  IGNORED_FIELDS_FOR_CLONE = %w[id parent_id dataset_version_id created_at updated_at].freeze
  IGNORED_CATEGORY_FIELDS = %w[id dataset_version_id created_at updated_at].freeze

  # TODO: if user clones a version to build a new one from, once they save changes we should
  #       check for breaking changes and bump the version appropriately
  # TODO: provide choice of next major, minor, patch semver?

  # TODO: needs to clone enumeration_value_dataset_versions
  # Clone a version, its nodes and categories iteratively, maintaining the 'tree'
  def clone_version(new_version_no)
    transaction do
      new_version = DatasetVersion.create!(semver_version: new_version_no, dataset_id: dataset_id)
      clone_categories(new_version)
      clone_nodes(new_version)
      clone_enumeration_value_dataset_versions(new_version)
      new_version
    end
  end

  def build_child(new_node, original_node, dataset_version)
    child_node = build_node(original_node.type, original_node, dataset_version)
    new_node.child_nodes << child_node
    return if original_node.child_nodes.blank?

    original_node.child_nodes.each do |child|
      build_child(child_node, child, dataset_version)
    end
  end

  def build_node(type, original_node, dataset_version)
    new_attrs = original_node.attributes.except(*IGNORED_FIELDS_FOR_CLONE)
    new_node = type.constantize.new(new_attrs)
    new_node.dataset_version = dataset_version
    build_node_categories(new_node, original_node, dataset_version) if
      original_node.categories.present?
    new_node
  end

  def build_node_categories(new_node, original_node, dataset_version)
    new_node.categories = original_node.categories.map do |category|
      Category.find_by(dataset_version: dataset_version, name: category.name)
    end
  end

  # TODO: add test
  def immediate_child_entities_of_record
    first_level_of_version_child_entities.each_with_object([]) do |version_child_entity, r|
      preloaded_entities.each do |e|
        r << e if e.parent_entity_in_tree == version_child_entity
      end
    end
  end

  def first_level_of_version_child_entities
    preloaded_entities.find_all { |n| n.parent_entity_in_tree == version_entity }
  end

  # For some fields we only want to select one node for many occurences in the db
  # e.g in Births ICDPVF occurs 20 times in the db but only one justificatio is needed on
  # the application
  # This is handled by a Nodes::DataItemGroup
  def data_items_and_data_item_groups
    return data_items if data_item_groups.empty?

    data_items.reject do |item|
      data_item_groups.pluck(:name).include? item.parent_node.name
    end
  end

  def schema_version_format
    semver_version.gsub('.', '-')
  end

  # Only one category per version can be designated as the 'Core' category
  def ensure_only_one_core_category
    return if categories.blank?
    return unless categories.find_all(&:core).count > 1

    errors.add(:dataset_version_categories, 'Only one Core category allowed')
  end

  def core_category
    return if categories.blank?
    
    categories.find(&:core)
  end

  def ensure_core_category_present
    return if categories.blank?
    return if core_category.present?

    errors.add(:dataset_version, 'Core category must be selected')
  end

  private

  # in some sort of order
  def xml_types_for_version
    child_node_xml_types(xml_types = [], version_entity)
    xml_types
  end

  def child_node_xml_types(collection, node)
    node.child_nodes.each do |child_node|
      if child_node.data_item?
        collection << child_node.xmltype unless collection.include? child_node.xmltype
      end
      child_node_xml_types(collection, child_node)
    end
  end

  def clone_categories(dataset_version)
    categories.each do |category|
      c = Category.new(category.attributes.except(*IGNORED_CATEGORY_FIELDS))
      c.dataset_version = dataset_version
      c.save!
    end
  end

  def clone_nodes(dataset_version)
    new_version_entity = build_node(version_entity.type, version_entity, dataset_version)
    version_entity.child_nodes.each do |child_node|
      build_child(new_version_entity, child_node, dataset_version)
    end
    new_version_entity.save!
  end

  # set the new cloned version to build enueration values
  def clone_enumeration_value_dataset_versions(dataset_version)
    enumeration_value_dataset_versions.each do |ev_dv|
      dataset_version.enumeration_value_dataset_versions.create!(
        enumeration_value: ev_dv.enumeration_value
      )
    end
  end

  def create_version_entity
    entity = Nodes::Entity.new(name: name, min_occurs: 1, max_occurs: 2,
                               description: dataset.description, sort: 0)
    nodes << entity
  end

  def nodes_valid_for_schema_build?
    return unless dataset.dataset_type.name == 'xml'
    return if data_items.empty?

    nodes.each do |node|
      return false unless node.valid?(:publish)
    end
    true
  end

  def invalid_nodes_for_schema_build
    nodes.each_with_object([]) do |node, invalid|
      invalid.push node unless node.valid?(:publish)
      invalid.push node if node.warnings.full_messages.present?
    end
  end

  def zip_filename
    "#{name}_v#{semver_version}.zip"
  end

  def publish
    update_attribute!(:published, true)
  end
end
