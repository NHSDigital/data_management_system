# COSD Categories e.g Breast, CNS, Other
class Category < ApplicationRecord
  has_many :node_categories, foreign_key: 'category_id', inverse_of: :category,
                             dependent: :destroy
  has_many :nodes, through: :node_categories, foreign_key: 'node_id'

  belongs_to :dataset_version

  validates :name, uniqueness: { scope: :dataset_version,
                                 message: 'One occurrence per version' }

  before_destroy prepend: true do
    throw(:abort) if in_use?
  end
  
  def in_use?
    NodeCategory.where(category_id: id).count.positive?
  end
end
