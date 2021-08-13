# Model for the ProjectDatasetLevel class
class ProjectDatasetLevel < ApplicationRecord
  belongs_to :project_dataset
  delegate :project, to: :project_dataset
  before_update :set_decided_at_to_nil
  after_update :notify_cas_approved_change
  after_create :set_expiry_date_to_one_year
  after_create :set_previous_level_current_to_false

  validate :expiry_date_must_be_present_for_level_one_or_extra_datasets

  def level_2_3_default?
    project_dataset.dataset.cas_defaults? && [2, 3].include?(access_level_id)
  end

  def level_1_default?
    project_dataset.dataset.cas_defaults? && access_level_id == 1
  end

  # TODO: ensure this covers every situation
  def level_1_at_initial_access_request?
    level_1_default? && project.current_state.id == 'SUBMITTED' &&
      project.states.pluck(:id).count('SUBMITTED') == 1
  end

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
    return if expiry_date.present?

    errors.add :expiry_date, :must_have_expiry_date
  end

  def set_previous_level_current_to_false
    return if current == false

    project_dataset.project_dataset_levels.each do |pdl|
      next if pdl == self
      next unless access_level_id == pdl.access_level_id && pdl.current == true

      pdl.update(current: false)
    end
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
