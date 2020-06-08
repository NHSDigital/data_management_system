# Membership associations and validations
class Membership < ApplicationRecord
  # belongs_to :team
  belongs_to :member, foreign_key: 'user_id', class_name: 'User'
  has_many :project_memberships, dependent: :destroy

  # Allow for auditing/version tracking of Membership
  has_paper_trail

  scope :senior, -> { where(senior: true) }

  before_destroy do
    throw(:abort) if project_senior_user?
  end

  validate :not_admin_or_odr
  validates :user_id, uniqueness: { scope: [:team_id],
                                    message: 'already a member of this Team' }

  delegate :email, to: :member, prefix: true # member_email
  delegate :telephone, to: :member, prefix: true # member__telephone
  # TODO: Grants branch FIX ME
  # delegate :flagged_as_deleted?, to: :member, prefix: true # member_flagged_as_deleted?
  delegate :full_name, to: :member, prefix: true # member_full_name
  delegate :location, to: :member, prefix: true # member_location
  delegate :name, to: :team, prefix: true # team_name
  delegate :z_user_status, to: :member, prefix: true # member_z_user_status

  # Returns true if self.member is the
  # senior user in any project
  def project_senior_user?
    project_memberships.select(&:senior_user?).any?
  end

  # Returns the project names (as a sentnce)
  # for which self.member is the senior user
  def senior_user_project_names
    project_memberships.select(&:senior_user?).map(&:project_name).to_sentence
  end

  def not_admin_or_odr
    if !member.nil? && (member.administrator? || member.odr?)
      errors.add(:user, 'Member cannot be an Adminsitrator or ODR user')
    end
  end
end
