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

    private

    def ensure_state_is_transitionable
      return unless project&.current_state && state
      return if project.transitionable_states.exists?(state.id)

      errors.add(:state, :invalid)
    end
  end
end
