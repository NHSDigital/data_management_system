module Nodes
  module Entities
    module Validations
      extend ActiveSupport::Concern
      included do
        caution :warn_against_no_child_nodes

        def warn_against_no_child_nodes
          warnings.add(:node, 'No Child nodes for Entity node') if child_nodes.blank?
        end
      end
    end
  end
end