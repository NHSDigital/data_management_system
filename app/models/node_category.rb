# Has many through for Data Item Category
class NodeCategory < ApplicationRecord
  belongs_to :node, class_name: 'Node', foreign_key: 'node_id', inverse_of: :node_categories
  belongs_to :category
end
