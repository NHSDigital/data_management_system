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
  end
end
