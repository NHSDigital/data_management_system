# -
class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :commentable, polymorphic: true

  validates :body, presence: true

  delegate :full_name, to: :user, prefix: true

  has_paper_trail
end
