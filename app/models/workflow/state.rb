module Workflow
  # Represents a position within a workflow.
  # See the workflows section of the README for more.
  class State < ApplicationRecord
    self.table_name_prefix = 'workflow_'

    INACTIVE = %w[DELETED SUSPENDED CLOSED EXPIRED].freeze
    CLOSED   = %w[APPROVED REJECTED CLOSED DELETED DATA_DESTROYED].freeze

    has_many :transitions, foreign_key: :from_state_id, inverse_of: :from_state, dependent: :destroy
    has_many :transitionable_states, through: :transitions, source: :next_state

    scope :terminal,     -> { left_joins(:transitions).where(workflow_transitions: { id: nil }) }
    scope :non_terminal, -> { joins(:transitions).distinct }

    scope :applicable_to, lambda { |*project_types|
      joins(:transitions).merge(Transition.applicable_to(*project_types)).distinct
    }

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
    scope :closed,                      -> { where(id: CLOSED) }
    scope :open,                        -> { where.not(id: CLOSED) }

    # Get a humanised name from localisation files:
    def name(*project_types)
      return id if project_types.none?

      lookup_key   = to_lookup_key
      context_keys = project_types.map do |project_type|
        :"#{project_type.to_lookup_key}.#{lookup_key}"
      end

      translations = I18n.t(context_keys, scope: model_name.i18n_key, default: '')
      translations.uniq!
      translations.reject!(&:blank?)

      translations.any? ? translations.join('/') : id
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

    def closed?
      id.in?(CLOSED)
    end

    def open?
      !closed?
    end
  end
end
