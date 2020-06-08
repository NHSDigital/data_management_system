require 'test_helper'

module Workflow
  # Tests grants relating to the EOI workflow.
  class EoiWorkflowTest < ActiveSupport::TestCase
    def setup
      @project = create_project(
        team: teams(:team_one),
        project_type: project_types(:eoi),
        project_purpose: 'test',
        assigned_user: users(:application_manager_one)
      )
    end

    test 'project workflow as basic user' do
      user = users(:standard_user1)

      @project.stubs current_state: workflow_states(:draft)
      refute user.can? :create, @project.project_states.build(state: workflow_states(:deleted))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:submitted))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:approved))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:rejected))

      @project.stubs current_state: workflow_states(:submitted)
      refute user.can? :create, @project.project_states.build(state: workflow_states(:draft))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:deleted))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:approved))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:rejected))

      @project.stubs current_state: workflow_states(:rejected)
      refute user.can? :create, @project.project_states.build(state: workflow_states(:draft))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:deleted))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:submitted))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:approved))

      @project.stubs current_state: workflow_states(:approved)
      refute user.can? :create, @project.project_states.build(state: workflow_states(:draft))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:deleted))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:submitted))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:rejected))

      @project.stubs current_state: workflow_states(:deleted)
      refute user.can? :create, @project.project_states.build(state: workflow_states(:draft))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:submitted))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:approved))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:rejected))
    end

    test 'project workflow as project member' do
      user = users(:standard_user1)

      @project.stubs current_state: workflow_states(:draft)
      refute user.can? :create, @project.project_states.build(state: workflow_states(:deleted))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:submitted))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:approved))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:rejected))

      @project.stubs current_state: workflow_states(:submitted)
      refute user.can? :create, @project.project_states.build(state: workflow_states(:draft))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:deleted))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:approved))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:rejected))

      @project.stubs current_state: workflow_states(:rejected)
      refute user.can? :create, @project.project_states.build(state: workflow_states(:draft))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:deleted))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:submitted))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:approved))

      @project.stubs current_state: workflow_states(:approved)
      refute user.can? :create, @project.project_states.build(state: workflow_states(:draft))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:deleted))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:submitted))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:rejected))

      @project.stubs current_state: workflow_states(:deleted)
      refute user.can? :create, @project.project_states.build(state: workflow_states(:draft))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:submitted))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:approved))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:rejected))
    end

    test 'project workflow as project senior' do
      user = users(:standard_user2)

      @project.stubs current_state: workflow_states(:draft)
      assert user.can? :create, @project.project_states.build(state: workflow_states(:deleted))
      assert user.can? :create, @project.project_states.build(state: workflow_states(:submitted))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:approved))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:rejected))

      @project.stubs current_state: workflow_states(:submitted)
      assert user.can? :create, @project.project_states.build(state: workflow_states(:draft))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:deleted))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:approved))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:rejected))

      @project.stubs current_state: workflow_states(:rejected)
      refute user.can? :create, @project.project_states.build(state: workflow_states(:draft))
      assert user.can? :create, @project.project_states.build(state: workflow_states(:deleted))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:submitted))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:approved))

      @project.stubs current_state: workflow_states(:approved)
      refute user.can? :create, @project.project_states.build(state: workflow_states(:draft))
      assert user.can? :create, @project.project_states.build(state: workflow_states(:deleted))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:submitted))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:rejected))

      @project.stubs current_state: workflow_states(:deleted)
      refute user.can? :create, @project.project_states.build(state: workflow_states(:draft))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:submitted))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:approved))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:rejected))
    end

    test 'project workflow as team delegate' do
      user = users(:delegate_user1)

      @project.stubs current_state: workflow_states(:draft)
      refute user.can? :create, @project.project_states.build(state: workflow_states(:deleted))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:submitted))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:approved))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:rejected))

      @project.stubs current_state: workflow_states(:submitted)
      refute user.can? :create, @project.project_states.build(state: workflow_states(:draft))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:deleted))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:approved))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:rejected))

      @project.stubs current_state: workflow_states(:rejected)
      refute user.can? :create, @project.project_states.build(state: workflow_states(:draft))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:deleted))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:submitted))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:approved))

      @project.stubs current_state: workflow_states(:approved)
      refute user.can? :create, @project.project_states.build(state: workflow_states(:draft))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:deleted))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:submitted))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:rejected))

      @project.stubs current_state: workflow_states(:deleted)
      refute user.can? :create, @project.project_states.build(state: workflow_states(:draft))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:submitted))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:approved))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:rejected))
    end

    test 'project workflow as ODR user' do
      user = users(:application_manager_one)

      @project.stubs current_state: workflow_states(:draft)
      assert user.can? :create, @project.project_states.build(state: workflow_states(:deleted))
      assert user.can? :create, @project.project_states.build(state: workflow_states(:submitted))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:approved))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:rejected))

      @project.stubs current_state: workflow_states(:submitted)
      assert user.can? :create, @project.project_states.build(state: workflow_states(:draft))
      assert user.can? :create, @project.project_states.build(state: workflow_states(:deleted))
      assert user.can? :create, @project.project_states.build(state: workflow_states(:approved))
      assert user.can? :create, @project.project_states.build(state: workflow_states(:rejected))

      @project.stubs current_state: workflow_states(:rejected)
      refute user.can? :create, @project.project_states.build(state: workflow_states(:draft))
      assert user.can? :create, @project.project_states.build(state: workflow_states(:deleted))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:submitted))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:approved))

      @project.stubs current_state: workflow_states(:approved)
      refute user.can? :create, @project.project_states.build(state: workflow_states(:draft))
      assert user.can? :create, @project.project_states.build(state: workflow_states(:deleted))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:submitted))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:rejected))

      @project.stubs current_state: workflow_states(:deleted)
      refute user.can? :create, @project.project_states.build(state: workflow_states(:draft))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:submitted))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:approved))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:rejected))
    end

    test 'project workflow as administrator' do
      user = users(:admin_user)

      @project.stubs current_state: workflow_states(:draft)
      refute user.can? :create, @project.project_states.build(state: workflow_states(:deleted))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:submitted))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:approved))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:rejected))

      @project.stubs current_state: workflow_states(:submitted)
      refute user.can? :create, @project.project_states.build(state: workflow_states(:draft))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:deleted))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:approved))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:rejected))

      @project.stubs current_state: workflow_states(:rejected)
      refute user.can? :create, @project.project_states.build(state: workflow_states(:draft))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:deleted))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:submitted))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:approved))

      @project.stubs current_state: workflow_states(:approved)
      refute user.can? :create, @project.project_states.build(state: workflow_states(:draft))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:deleted))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:submitted))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:rejected))

      @project.stubs current_state: workflow_states(:deleted)
      refute user.can? :create, @project.project_states.build(state: workflow_states(:draft))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:submitted))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:approved))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:rejected))
    end
  end
end
