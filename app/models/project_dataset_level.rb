# Model for the ProjectDatasetLevel class
class ProjectDatasetLevel < ApplicationRecord
  belongs_to :project_dataset
  delegate :project, to: :project_dataset
  before_update :set_decided_at_to_nil
  after_update :notify_cas_approved_change
  after_create :set_expiry_date_to_one_year

  validate :expiry_date_must_be_present_for_level_one_or_extra_datasets
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

  def set_expiry_date_to_one_year
    return unless project.cas?
    return unless project_dataset.dataset.cas_defaults?
    return unless [2, 3].include? access_level_id

    update_column(:expiry_date, 1.year.from_now)
  end

  def expiry_date_must_be_present_for_level_one_or_extra_datasets
    return unless project.cas?
    return unless selected == true
    return if project_dataset.dataset.cas_extras? || [2, 3].include?(access_level_id)

    errors.add :project_datasets, 'expiry date must be present for all selected extra datasets ' \
                                  'and any selected level 1 default datasets'
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

  def set_decided_at_to_nil
    return unless approved.nil?

    self.decided_at = nil
  end
end
