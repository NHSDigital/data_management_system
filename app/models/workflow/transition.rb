module Workflow
  # Join model that links a `State` to other `State`s which it may go to next.
  # See the workflows section of the README for more.
  class Transition < ApplicationRecord
    self.table_name_prefix = 'workflow_'

    belongs_to :from_state, class_name: 'State'
    belongs_to :next_state, class_name: 'State'

    # A `Transition` can be restricted to certain `ProjectType`s. If left unassociated (i.e. NULL)
    # then a `Transition` should be treated as applicable to any `ProjectType`.
    belongs_to :project_type, optional: true

    scope :applicable_to, ->(project_type) {
      where(project_type: project_type).
        or(where(project_type: nil))
    }
  end
end
