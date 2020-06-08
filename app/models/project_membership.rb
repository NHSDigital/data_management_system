# ProjectMembership associations and validations
class ProjectMembership < ApplicationRecord
  belongs_to :project
  belongs_to :membership

  delegate :name, to: :project, prefix: true # project_name
  delegate :member, to: :membership
  delegate :member_full_name, to: :membership
  delegate :member_flagged_as_deleted?, to: :membership
  delegate :email, to: :member, prefix: true # member_email

  # Allow for auditing/version tracking of ProjectMembership
  has_paper_trail

  validates :membership_id, uniqueness: { scope: [:project_id],
                                          message: 'already a member of this project' }

  before_destroy do
    throw(:abort) if senior_user?
  end

  # Returns true if self is the project
  # membership of the project's senior user
  def senior_user?
    membership.member == project.senior_user
  end
end
