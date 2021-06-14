module Workflow
  # Represents a position within a workflow.
  # See the workflows section of the README for more.
  class State < ApplicationRecord
    self.table_name_prefix = 'workflow_'

    INACTIVE = %w[DELETED SUSPENDED CLOSED EXPIRED].freeze

    has_many :transitions, foreign_key: :from_state_id, inverse_of: :from_state, dependent: :destroy
    has_many :transitionable_states, through: :transitions, source: :next_state

    scope :terminal,     -> { left_joins(:transitions).where(workflow_transitions: { id: nil }) }
    scope :non_terminal, -> { joins(:transitions).distinct }

    scope :not_deleted, -> { where.not(id: 'DELETED') }
    scope :dataset_approval_states, lambda {
      where(id: %w[SUBMITTED ACCESS_APPROVER_APPROVED ACCESS_APPROVER_REJECTED ACCESS_GRANTED])
    }
    scope :reapply_dataset_states, lambda {
      where(id: %w[DRAFT SUBMITTED ACCESS_APPROVER_APPROVED ACCESS_APPROVER_REJECTED ACCESS_GRANTED])
    }
    scope :access_approval_states, lambda {
      where(id: %w[SUBMITTED ACCESS_APPROVER_APPROVED ACCESS_APPROVER_REJECTED])
    }
    scope :active,                      -> { where.not(id: INACTIVE) }
    scope :inactive,                    -> { where(id: INACTIVE) }
    scope :awaiting_sign_off,           -> { where(id: %w[DRAFT REVIEW SUBMITTED]) }
    scope :submitted_for_sign_off,      -> { where(id: %w[REVIEW SUBMITTED]) }
    scope :not_submitted_for_sign_off,  -> { where.not(id: %w[REVIEW SUBMITTED]) }

    # Get a humanised name from localisation files:
    def name(project)
      I18n.t(id.downcase.to_sym,
             scope: [model_name.i18n_key, project.project_type_name.downcase.to_sym], default: id)
    end

    # TODO: Try to push this to an association tied to roles/grants.
    def assignable_users
      return User.application_managers.in_use        if id.in? %w[DPIA_REVIEW DPIA_REJECTED]
      return User.application_managers.in_use        if id.in? %w[CONTRACT_REJECTED]
      return User.senior_application_managers.in_use if id.in? %w[DPIA_MODERATION]

      User.none
    end

    def to_lookup_key
      id.parameterize(separator: '_').to_sym
    end
  end
end
