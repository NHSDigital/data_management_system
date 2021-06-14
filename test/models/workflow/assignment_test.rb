require 'test_helper'

module Workflow
  class AssignmentTest < ActiveSupport::TestCase
    def setup
      @assignment = workflow_assignments(:one)
    end

    test 'belongs to a project state' do
      assert_instance_of ProjectState, @assignment.project_state
    end

    test 'belongs to an assigned user' do
      assert_instance_of User, @assignment.assigned_user
    end

    test 'optionally belongs to an assigning user' do
      @assignment.update!(assigning_user: users(:standard_user1))

      assert_instance_of User, @assignment.assigning_user
    end

    test 'has a project delegate' do
      assert_instance_of Project, @assignment.project
    end

    test 'is invalid without a project state' do
      @assignment.project_state = nil
      @assignment.valid?

      assert_includes @assignment.errors.details[:project_state], error: :blank
    end

    test 'is invalid without an assigned user' do
      @assignment.assigned_user = nil
      @assignment.valid?

      assert_includes @assignment.errors.details[:assigned_user], error: :blank
    end

    test 'is valid without an assigning user' do
      @assignment.assigning_user = nil
      @assignment.valid?

      refute_includes @assignment.errors.details[:assigning_user], error: :blank
    end

    test 'triggers a project to refresh cached state information on commit' do
      project_state = @assignment.project_state
      project       = @assignment.project

      project.expects(:refresh_workflow_state_information)

      Assignment.create(
        project_state: project_state,
        assigned_user: users(:application_manager_two),
        assigning_user: users(:application_manager_one)
      )
    end
  end
end
