class Governance < ApplicationRecord
  has_many :nodes, foreign_key: 'id'
end
