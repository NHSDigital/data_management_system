# Model for the ProjectDatasetLevel class
class ProjectDatasetLevel < ApplicationRecord
  belongs_to :project_dataset
  delegate :project, to: :project_dataset
  after_update :notify_cas_approved_change

  validates :access_level_id, uniqueness: { scope: :project_dataset_id }

  def notify_cas_approved_change
    return unless project.cas?
    # Should only be approving after DRAFT
    return if project.current_state&.id == 'DRAFT'
    return if approved.nil?

    User.cas_manager_and_access_approvers.each do |user|
      CasNotifier.dataset_level_approved_status_updated(project, self, user.id)
    end
    CasMailer.with(project: project, project_dataset_level: self).send(
      :dataset_level_approved_status_updated
    ).deliver_later

    approved_change_to_user
  end

  def readable_approved_status
    return 'Undecided' if approved.nil?

    approved ? 'Approved' : 'Rejected'
  end

  private

  def approved_change_to_user
    CasNotifier.dataset_level_approved_status_updated_to_user(project, self)
    CasMailer.with(project: project, project_dataset_level: self).send(
      :dataset_level_approved_status_updated_to_user
    ).deliver_later
  end
end
