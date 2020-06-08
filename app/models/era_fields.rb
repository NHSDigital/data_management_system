# Store era metadata for a node in another table
class EraFields < ApplicationRecord
  belongs_to :node
end
