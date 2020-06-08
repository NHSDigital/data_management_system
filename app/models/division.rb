class Division < ApplicationRecord
  belongs_to :directorate
  has_many :teams
  has_many :users

  default_scope { where active: true }

  validates :name, presence: true
  validates :name, uniqueness: {scope: :directorate_id}

  def active_delegates
    users.in_use.delegate_users.count
  end

  def name_and_head
    return if name.nil? || head_of_profession.nil?

    name + ', ' + head_of_profession + '(' + active_delegates.to_s + ')'
  end
end
