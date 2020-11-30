require 'test_helper'

module Workflow
  # Tests grants relating to the CAS workflow.
  class CasWorkflowTest < ActiveSupport::TestCase
    def setup
      @project = create_project(
        project_type: project_types(:cas),
        project_purpose: 'test')
    end

    test 'project workflow as basic user' do
      user = users(:no_roles)

      @project.stubs current_state: workflow_states(:draft)
      assert user.can? :create, @project.project_states.build(state: workflow_states(:deleted))
      assert user.can? :create, @project.project_states.build(state: workflow_states(:submitted))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:awaiting_account_approval))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:approved))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:rejected))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:access_granted))

      @project.stubs current_state: workflow_states(:submitted)
      assert user.can? :create, @project.project_states.build(state: workflow_states(:draft))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:deleted))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:awaiting_account_approval))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:approved))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:rejected))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:access_granted))

      @project.stubs current_state: workflow_states(:awaiting_account_approval)
      refute user.can? :create, @project.project_states.build(state: workflow_states(:draft))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:deleted))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:submitted))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:approved))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:rejected))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:access_granted))

      @project.stubs current_state: workflow_states(:rejected)
      assert user.can? :create, @project.project_states.build(state: workflow_states(:draft))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:deleted))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:awaiting_account_approval))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:submitted))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:approved))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:access_granted))

      @project.stubs current_state: workflow_states(:approved)
      refute user.can? :create, @project.project_states.build(state: workflow_states(:draft))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:deleted))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:awaiting_account_approval))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:submitted))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:rejected))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:access_granted))

      @project.stubs current_state: workflow_states(:deleted)
      refute user.can? :create, @project.project_states.build(state: workflow_states(:draft))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:submitted))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:awaiting_account_approval))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:approved))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:rejected))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:access_granted))

      @project.stubs current_state: workflow_states(:access_granted)
      refute user.can? :create, @project.project_states.build(state: workflow_states(:draft))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:submitted))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:awaiting_account_approval))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:approved))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:rejected))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:deleted))
    end

    test 'project workflow as account approver' do
      user = users(:cas_access_approver)

      @project.stubs current_state: workflow_states(:draft)
      assert user.can? :create, @project.project_states.build(state: workflow_states(:deleted))
      assert user.can? :create, @project.project_states.build(state: workflow_states(:submitted))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:awaiting_account_approval))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:approved))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:rejected))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:access_granted))

      @project.stubs current_state: workflow_states(:submitted)
      assert user.can? :create, @project.project_states.build(state: workflow_states(:draft))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:deleted))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:awaiting_account_approval))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:approved))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:rejected))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:access_granted))

      @project.stubs current_state: workflow_states(:awaiting_account_approval)
      refute user.can? :create, @project.project_states.build(state: workflow_states(:draft))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:deleted))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:submitted))
      assert user.can? :create, @project.project_states.build(state: workflow_states(:approved))
      assert user.can? :create, @project.project_states.build(state: workflow_states(:rejected))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:access_granted))

      @project.stubs current_state: workflow_states(:rejected)
      assert user.can? :create, @project.project_states.build(state: workflow_states(:draft))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:deleted))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:awaiting_account_approval))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:submitted))
      assert user.can? :create, @project.project_states.build(state: workflow_states(:approved))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:access_granted))

      @project.stubs current_state: workflow_states(:approved)
      refute user.can? :create, @project.project_states.build(state: workflow_states(:draft))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:deleted))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:awaiting_account_approval))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:submitted))
      assert user.can? :create, @project.project_states.build(state: workflow_states(:rejected))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:access_granted))

      @project.stubs current_state: workflow_states(:deleted)
      refute user.can? :create, @project.project_states.build(state: workflow_states(:draft))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:submitted))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:awaiting_account_approval))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:approved))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:rejected))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:access_granted))

      @project.stubs current_state: workflow_states(:access_granted)
      refute user.can? :create, @project.project_states.build(state: workflow_states(:draft))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:submitted))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:awaiting_account_approval))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:approved))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:rejected))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:deleted))
    end

    test 'project workflow as cas manager' do
      user = users(:cas_manager)

      @project.stubs current_state: workflow_states(:draft)
      refute user.can? :create, @project.project_states.build(state: workflow_states(:deleted))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:submitted))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:awaiting_account_approval))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:approved))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:rejected))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:access_granted))

      @project.stubs current_state: workflow_states(:submitted)
      refute user.can? :create, @project.project_states.build(state: workflow_states(:draft))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:deleted))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:awaiting_account_approval))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:approved))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:rejected))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:access_granted))

      @project.stubs current_state: workflow_states(:awaiting_account_approval)
      refute user.can? :create, @project.project_states.build(state: workflow_states(:draft))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:deleted))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:submitted))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:approved))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:rejected))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:access_granted))

      @project.stubs current_state: workflow_states(:rejected)
      refute user.can? :create, @project.project_states.build(state: workflow_states(:draft))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:deleted))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:awaiting_account_approval))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:submitted))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:approved))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:access_granted))

      @project.stubs current_state: workflow_states(:approved)
      refute user.can? :create, @project.project_states.build(state: workflow_states(:draft))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:deleted))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:awaiting_account_approval))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:submitted))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:rejected))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:access_granted))

      @project.stubs current_state: workflow_states(:deleted)
      refute user.can? :create, @project.project_states.build(state: workflow_states(:draft))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:submitted))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:awaiting_account_approval))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:approved))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:rejected))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:access_granted))

      @project.stubs current_state: workflow_states(:access_granted)
      refute user.can? :create, @project.project_states.build(state: workflow_states(:draft))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:submitted))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:awaiting_account_approval))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:approved))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:rejected))
      refute user.can? :create, @project.project_states.build(state: workflow_states(:deleted))
    end

    test 'project workflow as administrator' do
      user = users(:admin_user)
    end
  end
end
