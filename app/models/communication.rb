# Records when dialogue between applicants and application management took place.
class Communication < ApplicationRecord
  include Commentable

  belongs_to :project

  belongs_to :sender,    class_name: 'User'
  belongs_to :recipient, class_name: 'User'

  belongs_to :parent, class_name:  'Communication', optional: true
  has_many :children, class_name:  'Communication',
                      foreign_key: :parent_id,
                      inverse_of:  :parent,
                      dependent:   :destroy

  has_paper_trail

  enum medium: { email: 1, phone: 2, letter: 3, in_person: 4 }

  validates :medium,       presence: true
  validates :contacted_at, presence: true
  validates :contacted_at, date: { no_future: true }
  validates :contacted_at, date: { not_before: :parent_contacted_at }, if: -> { parent_id.present? }

  with_options prefix: true do
    delegate :full_name,    to: :sender
    delegate :full_name,    to: :recipient
    delegate :contacted_at, to: :parent
  end
end
