require 'test_helper'

module Workflow
  # Tests the behaviour of the CurrentProjectState class.
  class CurrentProjectStateTest < ActiveSupport::TestCase
    def setup
      @project = projects(:dummy_project)
    end

    test 'should inherit from ProjectState' do
      assert_equal ProjectState, CurrentProjectState.superclass
    end

    test 'should be read only' do
      current_project_state = CurrentProjectState.new(
        project: @project,
        state: workflow_states(:step_one)
      )

      assert current_project_state.readonly?
      assert_raises ActiveRecord::ReadOnlyRecord do
        current_project_state.save(validate: false)
      end
    end
  end
end
