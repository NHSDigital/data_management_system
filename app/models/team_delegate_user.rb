class TeamDelegateUser < ApplicationRecord
  # belongs_to :team, inverse_of: :team_delegate_users
  # belongs_to :delegate_user, class_name: 'User', foreign_key: :user_id

  has_paper_trail
end
