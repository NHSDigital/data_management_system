class Directorate < ApplicationRecord
  has_many :divisions
  has_many :teams
  has_many :users

  validates :name, presence: true, uniqueness: true

  scope :active, -> { where active: true }

  def active_delegates
    divisions.sum { |d| d.users.in_use.delegate_users.count }
  end

end
