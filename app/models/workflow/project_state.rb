module Workflow
  # Maintains a history of `State`s in which a `Project` has been.
  # See the workflows section of the README for more.
  class ProjectState < ApplicationRecord
    self.table_name_prefix = 'workflow_'

    include Commentable

    belongs_to :project
    belongs_to :state

    # Track who was responsible for putting `Project` into this `State`.
    belongs_to :user, optional: true

    with_options inverse_of: :project_state do
      has_many :project_attachments
      has_many :assignments, dependent: :destroy
    end

    validate :ensure_state_is_transitionable, on: :create
    after_save :update_project_closure_date
    after_save :remove_project_closure_date
    after_save :submitted_state_notifiers
    after_save :notify_cas_manager_approver_application_approved_rejected
    after_save :notify_user_cas_application_approved
    after_save :notify_user_cas_application_rejected
    after_save :notify_cas_access_granted
    after_save :notify_requires_renewal
    after_save :notify_account_renewed
    after_save :notify_account_closed
    after_save :auto_transition_access_approver_approved_to_access_granted

    delegate :assigned_user, :assigning_user, to: :current_assignment, allow_nil: true
    delegate :full_name, to: :assigned_user,  prefix: true, allow_nil: true
    delegate :full_name, to: :assigning_user, prefix: true, allow_nil: true
    delegate :assignable_users, to: :state

    def current_assignment
      assignments.order(id: :desc).limit(1).first
    end

    def assign_to!(user:, assigning_user: nil)
      method = persisted? ? :create! : :build

      assignments.public_send(method, assigned_user: user, assigning_user: assigning_user)
    end

    def assign_to(user:, assigning_user: nil)
      assign_to!(user: user, assigning_user: assigning_user)
    rescue ActiveRecord::RecordInvalid
      false
    end

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

      notify_and_mail_requires_dataset_approval(project)

      User.cas_access_approvers.each do |user|
        CasNotifier.requires_account_approval(project, user.id)
      end
      CasMailer.with(project: project).send(:requires_account_approval).deliver_later

      User.cas_managers.each do |user|
        CasNotifier.application_submitted(project, user.id)
      end
      CasMailer.with(project: project).send(:application_submitted).deliver_later
    end

    def notify_cas_manager_approver_application_approved_rejected
      return unless project.cas?
      return unless %w[ACCESS_APPROVER_APPROVED ACCESS_APPROVER_REJECTED].include? state_id

      User.cas_manager_and_access_approvers.each do |user|
        CasNotifier.access_approval_status_updated(project, user.id, state_id)
      end
      CasMailer.with(project: project).send(:access_approval_status_updated).deliver_later
    end

    def notify_user_cas_application_approved
      return unless project.cas?
      return unless state_id == 'ACCESS_APPROVER_APPROVED'

      CasNotifier.account_approved_to_user(project)
      CasMailer.with(project: project).send(:account_approved_to_user).deliver_later
    end

    def notify_user_cas_application_rejected
      return unless project.cas?
      return unless state_id == 'REJECTION_REVIEWED'

      CasNotifier.account_rejected_to_user(project)
      CasMailer.with(project: project).send(:account_rejected_to_user).deliver_later
    end

    def notify_cas_access_granted
      return unless project.cas?
      return unless state_id == 'ACCESS_GRANTED'

      User.cas_managers.each do |user|
        CasNotifier.account_access_granted(project, user.id)
      end
      CasMailer.with(project: project).send(:account_access_granted).deliver_later

      CasNotifier.account_access_granted_to_user(project)
      CasMailer.with(project: project).send(:account_access_granted_to_user).deliver_later
    end

    def notify_requires_renewal
      return unless project.cas?
      return unless state_id == 'RENEWAL'

      CasNotifier.requires_renewal_to_user(project)
      CasMailer.with(project: project).send(:requires_renewal_to_user).deliver_later
    end

    def notify_account_renewed
      return unless project.cas?
      return unless state_id == 'ACCESS_GRANTED'
      return unless project.current_state.id == 'RENEWAL'

      DatasetRole.fetch(:approver).users.each do |user|
        matching_datasets = project.project_datasets.any? do |pd|
          ProjectDataset.dataset_approval(user).include? pd
        end
        next unless matching_datasets

        CasNotifier.account_renewed_dataset_approver(project, user)
        CasMailer.with(project: project, user: user).send(:account_renewed_dataset_approver).
          deliver_later
      end

      User.cas_manager_and_access_approvers.each do |user|
        CasNotifier.account_renewed(project, user)
      end
      CasMailer.with(project: project).send(:account_renewed).deliver_later
    end

    def notify_account_closed
      return unless project.cas?
      return unless state_id == 'ACCOUNT_CLOSED'

      User.cas_managers.each do |user|
        CasNotifier.account_closed(project, user.id)
      end
      CasMailer.with(project: project).send(:account_closed).deliver_later
      CasNotifier.account_closed_to_user(project)
      CasMailer.with(project: project).send(:account_closed_to_user).deliver_later
    end

    def auto_transition_access_approver_approved_to_access_granted
      return unless project.cas?
      return unless state_id == 'ACCESS_APPROVER_APPROVED'

      # TODO: this is a stopgap and will need script to generate access adding here

      self.project_id = project_id
      self.state_id = 'ACCESS_GRANTED'
      save!
    end

    def notify_and_mail_requires_dataset_approval(project)
      DatasetRole.fetch(:approver).users.each do |user|
        matching_datasets = project.project_datasets.any? do |pd|
          ProjectDataset.dataset_approval(user, [nil]).include? pd
        end
        next unless matching_datasets

        CasNotifier.requires_dataset_approval(project, user.id)
        CasMailer.with(project: project, user: user).send(:requires_dataset_approval).deliver_later
      end
    end
  end
end
