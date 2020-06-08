module Nodes
  # For Table Specifications
  class Database < Node
    belongs_to :node, class_name: 'Node', foreign_key: 'parent_id',
                      optional: true, inverse_of: :databases
    has_many :tables, class_name: 'Nodes::Table', foreign_key: 'parent_id',
                      dependent: :destroy, inverse_of: :database

    caution :warn_against_no_child_nodes

    def warn_against_no_child_nodes
      warnings.add(:node, 'No Child nodes for Database node') if child_nodes.blank?
    end

    def to_xsd(_schema, _category = nil)
      raise 'Cannot currently build Schema from Database Node!'
    end

    def to_xml(_xml, _category = nil)
      raise 'Cannot currently build Schema from Database Node!'
    end

    def to_xml_choice(_options)
      raise 'Cannot currently build Schema from Database Node!'
    end
  end
end
