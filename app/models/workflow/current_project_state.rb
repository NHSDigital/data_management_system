module Workflow
  # Support class built on top of `ProjectState` to enable a quick and easy means of accessing
  # the current `State` of a given `Project` and the current `ProjectStateAssignment`.
  # See the workflows section of the README for more.
  class CurrentProjectState < ProjectState
    self.table_name = 'workflow_current_project_states'

    with_options class_name: 'User' do
      belongs_to :assigned_user
      belongs_to :assigning_user
    end

    # This model is backed by a database view.
    def readonly?
      true
    end
  end
end
