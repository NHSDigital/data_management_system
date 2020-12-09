require 'test_helper'

module Workflow
  # Tests behaviour of the ProjectState class.
  class ProjectStateTest < ActiveSupport::TestCase
    def setup
      @project_state = workflow_project_states(:one)
      @project = create_project(
        team: teams(:team_one),
        project_type: project_types(:application),
        project_purpose: 'previous state test',
        assigned_user: users(:application_manager_one)
      )
    end

    test 'should belong to a project' do
      assert_instance_of Project, @project_state.project
    end

    test 'should belong to a state' do
      assert_instance_of State, @project_state.state
    end

    test 'should optionally belong to a user' do
      assert_instance_of User, @project_state.user
    end

    test 'should be invalid without a project' do
      @project_state.stubs(ensure_state_is_transitionable: true)

      @project_state.project = nil
      @project_state.valid?
      assert_includes @project_state.errors.details[:project], error: :blank
    end

    test 'should be invalid without a state' do
      @project_state.stubs(ensure_state_is_transitionable: true)

      @project_state.state = nil
      @project_state.valid?
      assert_includes @project_state.errors.details[:state], error: :blank
    end

    test 'should not be invalid without a user' do
      @project_state.stubs(ensure_state_is_transitionable: true)

      @project_state.user = nil
      @project_state.valid?
      refute_includes @project_state.errors.details[:user], error: :blank
    end

    test 'should be invalid if state is not reachable' do
      project       = projects(:dummy_project)
      current_state = workflow_states(:draft)
      project_state = ProjectState.new(project: project, state: workflow_states(:step_one))

      project.stubs(current_state: current_state)

      project.stubs(transitionable_states: current_state.transitionable_states.none)
      project_state.valid?
      assert_includes project_state.errors.details[:state], error: :invalid

      project.stubs(transitionable_states: current_state.transitionable_states)
      project_state.valid?
      refute_includes project_state.errors.details[:state], error: :invalid
    end

    test 'closing application updates closure date and reason' do
      @project.transition_to!(workflow_states(:draft))
      @project.reload
      assert_changes -> { @project.closure_date } do
        @project.transition_to!(workflow_states(:rejected))
      end
    end

    test 'reopening application removes closure date and reason' do
      @project.transition_to!(workflow_states(:draft))
      @project.transition_to!(workflow_states(:submitted))
      @project.transition_to!(workflow_states(:rejected))
      @project.update(closure_date: Date.current, closure_reason_id: Lookups::ClosureReason.first.id)
      assert_changes -> { @project.closure_date } do
        assert_changes -> { @project.closure_reason_id } do
          @project.transition_to!(workflow_states(:submitted))
        end
      end
    end

    test 'should auto-transition cas application if there are no project datasets to approve' do
      application = Project.new(project_type: ProjectType.find_by(name: 'CAS')).tap do |a|
        a.owner = users(:no_roles)
        a.save!
      end

      application.transition_to!(workflow_states(:submitted))

      assert_equal application.current_state, workflow_states(:awaiting_account_approval)
    end

    test 'should not auto-transition cas application if not at submitted state' do
      application = Project.new(project_type: ProjectType.find_by(name: 'CAS')).tap do |a|
        a.owner = users(:no_roles)
        a.save!
      end

      application.save!

      refute_equal application.current_state, workflow_states(:awaiting_account_approval)
    end

    test 'should not auto-transition cas application if there are unresolved dataset decisions' do
      application = Project.new(project_type: ProjectType.find_by(name: 'CAS')).tap do |a|
        a.owner = users(:no_roles)
        a.project_datasets << ProjectDataset.new(dataset: dataset(83), terms_accepted: true,
                                                 approved: nil)
        a.project_datasets << ProjectDataset.new(dataset: dataset(84), terms_accepted: true,
                                                 approved: nil)
        a.save!
      end

      application.transition_to!(workflow_states(:submitted))

      refute_equal application.current_state, workflow_states(:awaiting_account_approval)
    end

    test 'should notify cas manager and access approvers on update to approved or rejected' do
      project = create_project(project_type: project_types(:cas), project_purpose: 'test')
      project.reload_current_state

      notifications = Notification.where(title: 'Access Approval Status Updated')
      # Should not send out notifications for changes when not approved or rejected
      assert_no_difference 'notifications.count' do
        project.transition_to!(workflow_states(:submitted))
        project.transition_to!(workflow_states(:awaiting_account_approval))
      end

      assert_difference 'notifications.count', 3 do
        project.transition_to!(workflow_states(:approved))
      end

      assert_equal notifications.last.body, "CAS project #{project.id} - Access approval status " \
                                            "has been updated to 'Approved'.\n\n"

      assert_difference 'notifications.count', 3 do
        project.transition_to!(workflow_states(:rejected))
      end

      assert_equal notifications.last.body, "CAS project #{project.id} - Access approval status " \
                                            "has been updated to 'Rejected'.\n\n"
    end

    test 'should notify user on update to approved' do
      project = create_project(project_type: project_types(:cas), project_purpose: 'test',
                               owner: users(:no_roles))
      project.reload_current_state

      notifications = Notification.where(title: 'CAS Access Approved')
      # Should not send out notifications for changes when not approved
      assert_no_difference 'notifications.count' do
        project.transition_to!(workflow_states(:submitted))
        project.transition_to!(workflow_states(:awaiting_account_approval))
      end

      assert_difference 'notifications.count', 1 do
        project.transition_to!(workflow_states(:approved))
      end

      assert_equal notifications.last.body, "Your CAS access has been approved for application " \
                                            "#{project.id}. You will receive a further " \
                                            "notification once your account has been updated"
    end

    test 'should notify user on update to access granted' do
      project = create_project(project_type: project_types(:cas), project_purpose: 'test',
                               owner: users(:no_roles))
      project.reload_current_state

      notifications = Notification.where(title: 'CAS Access Granted')
      # Should not send out notifications for changes when not access_granted
      assert_no_difference 'notifications.count' do
        project.transition_to!(workflow_states(:submitted))
        project.transition_to!(workflow_states(:awaiting_account_approval))
        project.transition_to!(workflow_states(:approved))
      end

      assert_difference 'notifications.count', 1 do
        project.transition_to!(workflow_states(:access_granted))
      end

      assert_equal notifications.last.body, "CAS access has been granted for your account based " \
                                            "on application #{project.id}."
    end

    test 'should notify cas manager on update to access granted' do
      project = create_project(project_type: project_types(:cas), project_purpose: 'test')
      project.reload_current_state

      notifications = Notification.where(title: 'CAS Access Status Updated')
      # Should not send out notifications for changes when not access_granted
      assert_no_difference 'notifications.count' do
        project.transition_to!(workflow_states(:submitted))
        project.transition_to!(workflow_states(:awaiting_account_approval))
        project.transition_to!(workflow_states(:approved))
      end

      assert_difference 'notifications.count', 2 do
        project.transition_to!(workflow_states(:access_granted))
      end

      assert_equal notifications.last.body, "CAS project #{project.id} - Access has been granted " \
                                            "by the helpdesk and the applicant now has CAS " \
                                            "access.\n\n"
    end
  end
end
