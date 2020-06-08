module Nodes
  # Model fo XSD Group
  class Group < Node
    belongs_to :node, class_name: 'Node', foreign_key: 'parent_id',
                      optional: true, inverse_of: :data_items
    has_many :data_items, class_name: 'Nodes::DataItem', foreign_key: 'parent_id',
                          dependent: :destroy, inverse_of: :group
    has_many :choices, class_name: 'Nodes::Choice', foreign_key: 'parent_id',
                       dependent: :destroy, inverse_of: :group
    has_many :entities, class_name: 'Nodes::Entity', foreign_key: 'parent_id',
                        dependent: :destroy, inverse_of: :group
    has_many :data_item_groups, class_name: 'Nodes::DataItemGroup', foreign_key: 'parent_id',
                                dependent: :destroy, inverse_of: :group

    caution :warn_against_no_child_nodes

    def warn_against_no_child_nodes
      warnings.add(:node, 'No Child nodes for Group node') if child_nodes.blank?
    end

    def to_xsd(schema, _category = nil)
      xsd_group_ref(schema, name)
    end

    # builds groups of elements that can be referenced.
    def to_xsd_groups(schema)
      xsd_group(schema, name) do |group_xsd|
        xsd_sequence(group_xsd) do |sequence|
          child_nodes.sort_by(&:sort).each do |node|
            node.to_xsd(sequence)
          end
        end
      end
    end

    # We don't require a group name for XML
    def to_xml(xml, category = nil)
      child_nodes.sort_by(&:sort).each do |child_node|
        child_node.to_xml(xml)
      end
    end
    
    def to_xml_choice(options)
      child_nodes.sort_by(&:sort).each do |child_node|
        child_node.to_xml_choice(options)
      end
    end
  end
end
