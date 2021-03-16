# node class
# TODO: node.name cannot contain spaces. breaks xsd and existing item view div_ids
class Node < ApplicationRecord
  include Xsd::Generator

  belongs_to :dataset_version, optional: true
  belongs_to :category_choice, class_name: 'Nodes::CategoryChoice', foreign_key: 'parent_id',
                               optional: true, inverse_of: :child_nodes
  has_many :category_choices, class_name: 'Nodes::CategoryChoice', foreign_key: 'parent_id',
                              inverse_of: :node, dependent: :destroy
  belongs_to :choice, class_name: 'Nodes::Choice', foreign_key: 'parent_id',
                      optional: true, inverse_of: :child_nodes
  has_many :choices, class_name: 'Nodes::Choice', foreign_key: 'parent_id',
                     inverse_of: :node, dependent: :destroy
  belongs_to :group, class_name: 'Nodes::Group', foreign_key: 'parent_id',
                     optional: true, inverse_of: :child_nodes
  has_many :groups, class_name: 'Nodes::Group', foreign_key: 'parent_id',
                    inverse_of: :node, dependent: :destroy
  belongs_to :entity, class_name: 'Nodes::Entity', foreign_key: 'parent_id',
                      optional: true, inverse_of: :child_nodes
  has_many :entities, class_name: 'Nodes::Entity', foreign_key: 'parent_id',
                      inverse_of: :node, dependent: :destroy
  has_many :child_nodes, class_name: 'Node', foreign_key: 'parent_id', inverse_of: :parent_node,
                         dependent: :destroy
  belongs_to :parent_node, class_name: 'Node', foreign_key: 'parent_id',
                           optional: true, inverse_of: :child_nodes
  accepts_nested_attributes_for :child_nodes, reject_if: :all_blank, allow_destroy: true
  has_many :data_items, class_name: 'Nodes::DataItem', foreign_key: 'parent_id', inverse_of: :node,
                        dependent: :destroy
  has_many :node_categories, class_name: 'NodeCategory', foreign_key: 'node_id',
                             inverse_of: :node, dependent: :destroy
  has_many :categories, through: :node_categories, class_name: 'Category',
                        foreign_key: 'category_id', dependent: :destroy
  belongs_to :governance, foreign_key: 'governance_id', optional: true

  has_many :project_nodes
  has_many :projects, through: :project_nodes

  has_many :node_version_mappings, foreign_key: 'node_id', inverse_of: :node, dependent: :destroy

  has_one :era_fields

  scope :data_items, -> { where(type: 'Nodes::DataItem') }
  scope :entities, -> { where(type: 'Nodes::Entity') }
  scope :groups, -> { where(type: 'Nodes::Group') }
  scope :mandatory, -> { where('min_occurs > 0') }
  scope :optional, -> { where(min_occurs: 0) }
  scope :sorted, -> { sort_by(&:sort) }

  validate :min_occur_must_not_be_nil
  validate :min_occur_not_greater_than_max_occurs
  validate :child_entities_are_uniquely_named

  accepts_nested_attributes_for :child_nodes, allow_destroy: true
  accepts_nested_attributes_for :node_categories, allow_destroy: true

  delegate :dataset, to: :dataset_version, prefix: false

  before_destroy prepend: true do
    throw(:abort) if in_use?
  end

  # Once all descendant "child nodes" have been loaded, what else should be?
  def self.preload_strategy
    [
      :categories,
      { dataset_version: :dataset },
      :parent_node # FIXME: some entity types set conflicting inverse_ofs, which reduces efficiency
    ]
  end

  def min_occur_must_not_be_nil
    return if type == 'Nodes::Group'
    return if type == 'Nodes::Choice'

    errors.add(:node, 'Minimum occurrences cannot be nil for this node') if min_occurs.nil?
  end

  def min_occur_not_greater_than_max_occurs
    return if type == 'Nodes::Group'
    return if type == 'Nodes::Choice'
    return if max_occurs.nil? # unbounded

    errors.add(:node, 'Min occurs cannot be greater than Max occurs') if min_occurs > max_occurs
  end

  # validate uniqueness of entity name at a branch level
  # i.e if entities are part of choice then that is in the level
  # This will avoid a duplicate complexType definition error in schema
  def child_entities_are_uniquely_named
    return if persisted?
    return if parent_node.nil?
    return if name.nil?
    return if db_node?
    return unless name_exists?

    error_msg = "Another entity already exists with this name: #{name}, type: #{type} at this level"
    errors.add(:node, error_msg) 
  end

  # TODO: Meed a consistent way to define this
  #       e.g if we need short name or basing it off annotation. Not all annotations are present.
  def xsd_element_name
    name =~ /\s/ ? name.gsub(/\s/, '_').downcase.camelize : name
  end

  def xsd_type_name(category = nil)
    type_name = xsd_element_name
    return type_name if category.nil?
    # If node contains nothing specific to category then reference a common group
    return type_name unless node_for_category?(category)
    # if any of the data items have this category
    return category + type_name if contains_child_nodes_specific_to?(category)

    type_name
  end

  def xsd_name(xsd_type, category = nil)
    Nodes::DatasetVersionLookup.lookup(dataset_version, xsd_type, name, category)
  end

  # 1. Build complex types
  def build(schema, category = nil)
    # We'll build common entities later
    complex_entity(schema, false, category) if build_entity?(category)
    child_nodes.sort_by(&:sort).each do |child_node|
      child_node.build(schema, category) unless child_node.category_choice?
      next unless child_node.category_choice?

      # If node is a category choice we are building a 'tree' for each category
      dataset_version.categories.sort_by(&:sort).each do |version_category|
        child_node.build(schema, version_category.name)
      end
    end
  end

  def build_entity?(category)
    entity? && node_for_category?(category) &&
      !Nodes::DatasetVersionLookup.common?(dataset_version, name, category)
  end

  def complex_entity(schema, common, category = nil)
    type_name = common ? xsd_element_name : xsd_name(:type_name, category)
    xsd_complex_type(schema, type_name) do |complex_type|
      xsd_sequence(complex_type) do |sequence|
        child_nodes.sort_by(&:sort).each do |child_node|
          child_node.to_xsd(sequence, category)
        end
      end
    end
  end

  # nil represents something common. so don't false if it has category specific nodes
  def node_for_category?(category = nil)
    belongs_to_all_categories? || belongs_to_category?(category)
  end

  def belongs_to_category?(category)
    return (categories.map(&:name).uniq.include? category) if category_node?
    return parent_entity_belongs_to_category?(category) if data_item? || group?
  end

  def parent_entity_belongs_to_category?(category)
    return if parent_node.nil?
    return parent_node.node_for_category?(category) if parent_node.entity?

    parent_node.parent_entity_belongs_to_category?(category)
  end

  def belongs_to_all_categories?
    return false unless category_node?

    categories.blank?
  end

  def contains_child_nodes_specific_to?(category)
    child_nodes.each do |child_node|
      next unless child_node.entity?
      return true if child_node.specific_to?(category)
    end
    child_nodes.each do |child_node|
      return true if child_node.contains_child_nodes_specific_to?(category)
    end
    false
  end

  def specific_to?(category)
    return unless entity?
    return false if categories.blank?

    categories.map(&:name).include? category
  end

  def max_occurrences
    max_occurs.nil? ? 'unbounded' : max_occurs
  end

  def max_occurrences_star
    return if group?

    max_occurs.presence || '*'
  end

  def min_occurrences
    min_occurs.presence || 0
  end

  def multiple_occurrences?
    max_occurrences == 'unbounded' || max_occurs > 1
  end

  def data_item?
    is_a?(Nodes::DataItem)
  end

  def entity?
    is_a?(Nodes::Entity)
  end

  def choice?
    is_a?(Nodes::Choice)
  end

  def group?
    is_a?(Nodes::Group)
  end

  def category_choice?
    is_a?(Nodes::CategoryChoice)
  end

  def category_node?
    entity? || choice?
  end
  
  def db_node?
    is_a?(Nodes::Database)
  end

  def table_node?
    is_a?(Nodes::Table)
  end

  def destroy_node
    destroy_children
    destroy
  end

  def destroy_children
    child_nodes.each do |child_node|
      child_node.destroy_children if child_nodes.present?
      child_node.destroy
    end
  end

  def parent_node_for_description
    return nil if parent_node.nil?
    return parent_node if parent_node_for_description?

    parent_node.parent_node_for_description
  end

  def parent_node_for_description?
    parent_node.choice? || parent_node.category_choice? || parent_node.entity?
  end

  # Traverse tree and find first node that is an entity
  def parent_entity_in_tree
    return nil if parent_node.nil?
    return parent_node if parent_node.entity?

    parent_node.parent_entity_in_tree
  end

  # keep going through parents
  def in_child_path_for?(node)
    return true if name == node.name
    return false if parent_node.nil?
    return true if parent_node.name == node.name

    parent_node.in_child_path_for?(node)
  end

  def parent_choices_to_get_to_this_choice(parent_choices = {})
    return parent_choices if parent_node.name == 'Record'

    parent_choices[parent_node.id] = self if parent_node.choice?
    parent_node.parent_choices_to_get_to_this_choice(parent_choices)
  end

  def excel_occurrence_text
    return if parent_node.nil?

    excel_occurrences + " per #{parent_node_for_description.name} " + excel_occurrence_detail
  end

  def excel_occurrence_detail
    return "(#{min_occurs}..*)" if max_occurs.nil?

    "(#{min_occurs}..#{max_occurs})"
  end

  def excel_occurrences
    return if parent_node_for_description.nil?
    return 'Must be one occurrence' if min_occurs == 1 && max_occurs == 1
    return "Must be at least #{min_occurs} occurrence(s)" if min_occurs.positive?
    return 'May be up to one occurrence' if min_occurs.zero? && max_occurs == 1
    return 'May be multiple occurrences' if min_occurs.zero? && max_occurs.nil?
  end

  def governance_value
    governance&.value
  end

  # TODO: probably doesn't belong here
  def highlighting
    case governance&.value
    when 'DIRECT IDENTIFIER'   then 'danger'
    when 'INDIRECT IDENTIFIER' then 'warning'
    else 'default'
    end
  end

  # TODO: probably doesn't belong here
  def colour
    case governance&.value
    when 'DIRECT IDENTIFIER'   then 'red'
    when 'INDIRECT IDENTIFIER' then 'orange'
    else 'green'
    end
  end

  # TODO: probably doesn't belong here
  def identifiable_icon
    case governance&.value
    when 'DIRECT IDENTIFIER'   then 'eye-open icon-danger'
    when 'INDIRECT IDENTIFIER' then 'eye-open icon-warning'
    else 'eye-close icon-success'
    end
  end

  def existing_name
    [id, name]
  end

  def existing_name=(existing_name)
    existing_name
  end

  def parent_node_name
    parent_node&.xsd_element_name
  end

  def previous_node_in(version)
    return if node_version_mappings.blank?

    version_mapping =
      node_version_mappings.detect { |n| n.previous_node.dataset_version.semver_version == version }
    version_mapping.previous_node
  end

  # Schema Generation method
  def build_generic(schema, category = nil)
    # We'll build common entities later
    complex_entity(schema, false, category) if build_entity?(category)
    child_nodes.sort_by(&:sort).each do |child_node|
      child_node.build_generic(schema, category) unless child_node.category_choice?
    end
  end

  # Schema Generation method
  def build_category(schema, category)
    child_nodes.sort_by(&:sort).each do |child_node|
      child_node.build_generic(schema, category)
    end
  end

  def parent_table_node
    return if parent_node.nil?
    return parent_node if parent_node.table_node?
    
    parent_node.parent_table_node
  end

  def preload_tree(children)
    ActiveRecord::Associations::Preloader.new.preload(children, :child_nodes)
    grandchildren = children.flat_map(&:child_nodes)

    if grandchildren.any?
      children + preload_tree(grandchildren)
    else
      children
    end
  end

  def preloaded_descendants
    descendants = preload_tree(child_nodes)
    descendants.group_by(&:class).each do |klass, instances|
      ActiveRecord::Associations::Preloader.new.preload(instances, klass.preload_strategy)
    end
    descendants
  end

  private

  def name_exists?
    Node.where(parent_node: parent_entity_in_tree).map(&:name).include? name
  end

  def in_use?
    projects.any?
  end
end
