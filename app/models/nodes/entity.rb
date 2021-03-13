module Nodes
  # Entity class
  class Entity < Node
    include Xsd::Generator
    include Nodes::Entities::Validations

    belongs_to :node, class_name: 'Node', foreign_key: 'parent_id',
                      optional: true, inverse_of: :data_items
    has_many :data_items, class_name: 'Nodes::DataItem', foreign_key: 'parent_id',
                          inverse_of: :entity, dependent: :destroy
    has_many :child_entities, class_name: 'Nodes::Entity', foreign_key: 'parent_id',
                              inverse_of: :parent_entity, dependent: :destroy
    belongs_to :parent_entity, class_name: 'Nodes::Entity', foreign_key: 'parent_id',
                               optional: true, inverse_of: :child_entities
    has_many :category_choices, class_name: 'Nodes::CategoryChoice', foreign_key: 'parent_id',
                                inverse_of: :entity, dependent: :destroy
    has_many :choices, class_name: 'Nodes::Choice', foreign_key: 'parent_id',
                       inverse_of: :entity, dependent: :destroy
    has_many :groups, class_name: 'Nodes::Group', foreign_key: 'parent_id', inverse_of: :entity,
                      dependent: :destroy

    belongs_to :choice, class_name: 'Nodes::Choice', foreign_key: 'parent_id',
                        optional: true, inverse_of: :entity
    belongs_to :group, class_name: 'Nodes::Group', foreign_key: 'parent_id',
                       optional: true, inverse_of: :entity
    scope :record, -> { find_by(name: 'Record') }

    def to_xsd(schema, category = nil)
      return unless
        Nodes::DatasetVersionLookup.entity_for_category?(dataset_version, category, name)
      entity_element(schema, category)
    end

    def entity_element(schema, category = nil)
      element_name = xsd_name(:element_name, category)
      entity_options = { name: element_name, type: xsd_name(:type_name, category),
                         minOccurs: min_occurs, maxOccurs: max_occurrences }
      build_element(schema, :element, entity_options)
    end

    def to_xml(xml, category = nil)
      return unless belongs_to_category?(category) || categories.blank?
      xml_entity(xml, category)
      # Build another entity if more than one occurrence allowed
      xml_entity(xml, category) if multiple_occurrences?
    end

    def to_xml_choice(options)
      # return if optional and choice is not in any of it's children and we not in the choice itself
      return if optional_for_sample? && !choice_in_children?(options)
      category = options[:category]&.name
      return unless belongs_to_category?(category) || categories.blank?
      xml_entity_choice(options)
    end
    
    def xml_entity_choice(options)
      options[:xml].send(xsd_element_name) do
        child_nodes.sort_by(&:sort).each do |child_node|
          child_node.to_xml_choice(options)
        end
      end
    end

    def xml_entity(xml, category = nil)
      xml.send(xsd_element_name) do
        entity_nodes = RANDOM_OPTIONAL_ELEMENTS ? random_node_selection : child_nodes
        entity_nodes.sort_by(&:sort).each do |child_node|
          child_node.to_xml(xml, category)
        end
      end
    end

    # must include mandatory nodes
    def random_node_selection
      max_optional_nodes = SecureRandom.random_number(child_nodes.optional.count + 1)
      child_nodes.mandatory + child_nodes.optional.sample(max_optional_nodes)
    end

    private

    def optional_for_sample?
      min_occurs.eql?(0) && name != 'Record'
    end
  
    def choice_in_children?(options)
      Array.wrap(options[:choice]).any? { |n| n.in_child_path_for?(self) }
    end
  end
end
