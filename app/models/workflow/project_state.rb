module Workflow
  # Maintains a history of `State`s in which a `Project` has been.
  # See the workflows section of the README for more.
  class ProjectState < ApplicationRecord
    self.table_name_prefix = 'workflow_'

    belongs_to :project
    belongs_to :state

    # Track who was responsible for putting `Project` into this `State`.
    belongs_to :user, optional: true

    has_many :project_attachments, inverse_of: :project_state

    validate :ensure_state_is_transitionable, on: :create
    after_save :update_project_closure_date
    after_save :remove_project_closure_date
    after_save :submitted_state_notifiers
    after_save :notify_cas_manager_approver_application_approved_rejected
    after_save :notify_user_cas_application_approved
    after_save :notify_user_cas_application_rejected
    after_save :notify_cas_access_granted

    private

    def ensure_state_is_transitionable
      return unless project&.current_state && state
      return if project.transitionable_states.exists?(state.id)

      errors.add(:state, :invalid)
    end

    def update_project_closure_date
      return unless state_id == 'REJECTED'

      project.update(closure_date: created_at)
    end

    def remove_project_closure_date
      return if state_id == 'REJECTED'
      return unless project.previous_state_id == 'REJECTED'

      project.update(closure_date: nil, closure_reason_id: nil)
    end

    def submitted_state_notifiers
      return unless project.cas?
      return unless state_id == 'SUBMITTED'

      DatasetRole.fetch(:approver).users.each do |user|
        matching_datasets = project.project_datasets.any? do |pd|
          ProjectDataset.dataset_approval(user, nil).include? pd
        end
        next unless matching_datasets

        CasNotifier.requires_dataset_approval(project, user.id)
        CasMailer.with(project: project, user: user).send(:requires_dataset_approval).deliver_now
      end

      SystemRole.fetch(:cas_access_approver).users.each do |user|
        CasNotifier.requires_account_approval(project, user.id)
      end
      CasMailer.with(project: project).send(:requires_account_approval).deliver_now

      SystemRole.fetch(:cas_manager).users.each do |user|
        CasNotifier.application_submitted(project, user.id)
      end
      CasMailer.with(project: project).send(:application_submitted).deliver_now
    end

    def notify_cas_manager_approver_application_approved_rejected
      return unless project.cas?
      return unless %w[ACCESS_APPROVER_APPROVED ACCESS_APPROVER_REJECTED].include? state_id

      SystemRole.cas_manager_and_access_approvers.map(&:users).flatten.each do |user|
        CasNotifier.access_approval_status_updated(project, user.id)
      end
      CasMailer.with(project: project).send(:access_approval_status_updated).deliver_now
    end

    def notify_user_cas_application_approved
      return unless project.cas?
      return unless state_id == 'ACCESS_APPROVER_APPROVED'

      CasNotifier.account_approved_to_user(project)
      CasMailer.with(project: project).send(:account_approved_to_user).deliver_now
    end

    def notify_user_cas_application_rejected
      return unless project.cas?
      return unless state_id == 'REJECTION_REVIEWED'

      CasNotifier.account_rejected_to_user(project)
      CasMailer.with(project: project).send(:account_rejected_to_user).deliver_now
    end

    def notify_cas_access_granted
      return unless project.cas?
      return unless state_id == 'ACCESS_GRANTED'

      SystemRole.fetch(:cas_manager).users.each do |user|
        CasNotifier.account_access_granted(project, user.id)
      end

      CasNotifier.account_access_granted_to_user(project)
      CasMailer.with(project: project).send(:account_access_granted_to_user).deliver_now
    end
  end
end
