# Aim here is to track what a node was in a previous version when
# every identifiable attribute has changed
# i.e a node has changed reference and name but is still same node
# e.g NHSNumber => NhsNumber, CR0000 => CR0001
class NodeVersionMapping < ApplicationRecord
  belongs_to :node, foreign_key: 'node_id', inverse_of: :node_version_mappings
  belongs_to :previous_node, class_name: 'Node', foreign_key: 'previous_node_id',
                             inverse_of: :node_version_mappings

  validates :node_id, uniqueness: { scope: :previous_node_id }
  validate :mapped_nodes_belong_to_same_dataset

  def mapped_nodes_belong_to_same_dataset
    return if node.dataset == previous_node.dataset

    errors.add(:dataset, 'Nodes do not belong to same Dataset!')
  end
end
