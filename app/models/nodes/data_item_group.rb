module Nodes
  # For Table Specifications
  # A selectable node for an application that reduces need 
  class DataItemGroup < Node
    belongs_to :node, class_name: 'Node', foreign_key: 'parent_id',
                      optional: true, inverse_of: :tables
    belongs_to :group, class_name: 'Nodes::Group', foreign_key: 'parent_id',
                       optional: true, inverse_of: :tables
    has_many :data_items, class_name: 'Nodes::DataItem', foreign_key: 'parent_id',
                          dependent: :destroy, inverse_of: :table

    caution :warn_against_no_child_nodes

    def warn_against_no_child_nodes
      warnings.add(:node, 'No Child nodes for Table node') if child_nodes.blank?
    end

    def to_xsd(_schema, _category = nil)
      raise 'Cannot currently build Schema from DataItemGroup Node!'
    end

    def to_xml(_xml, _category = nil)
      raise 'Cannot currently build Schema from DataItemGroup Node!'
    end

    def to_xml_choice(_options)
      raise 'Cannot currently build Schema from DataItemGroup Node!'
    end
  end
end
