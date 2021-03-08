# -
class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :commentable, polymorphic: true

  validates :body, presence: true

  delegate :full_name, to: :user, prefix: true

  has_paper_trail

  store_accessor :metadata, :tags

  after_initialize :initialize_tags
  before_save :reject_blank_tags

  scope :tagged_with, ->(*tags) { where("metadata -> 'tags' ?| ARRAY[:tags]", tags: tags) }

  private

  def initialize_tags
    self.tags ||= []
  end

  def reject_blank_tags
    tags.reject!(&:blank?)
  end
end
