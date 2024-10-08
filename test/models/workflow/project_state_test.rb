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

    test 'has many assignments' do
      assert_instance_of Assignment, @project_state.assignments.first
    end

    test 'should fetch current assignment' do
      assignment = workflow_assignments(:one)

      assert_equal assignment, @project_state.current_assignment
    end

    test 'should fetch currently assigned user' do
      user = users(:standard_user1)

      assert_equal user, @project_state.assigned_user
    end

    test 'should assign a user' do
      user_one = users(:application_manager_one)
      user_two = users(:application_manager_two)

      assert_difference -> { @project_state.assignments.count } do
        assignment = @project_state.assign_to(user: user_two, assigning_user: user_one)

        assert_equal user_one, assignment.assigning_user
        assert_equal user_two, assignment.assigned_user
      end
    end

    test 'assignable_users' do
      user_one = users(:application_manager_one)
      user_two = users(:application_manager_two)

      # Default case - project users + application managers...
      assert_includes @project_state.assignable_users, @project_state.project.owner
      assert_includes @project_state.assignable_users, user_one
      assert_includes @project_state.assignable_users, user_two

      # With state mandated subset of users/roles...
      @project_state.state.stubs(assignable_users: [user_one])
      refute_includes @project_state.assignable_users, @project_state.project.owner
      assert_includes @project_state.assignable_users, user_one
      refute_includes @project_state.assignable_users, user_two

      # Guard...
      @project_state.state = nil
      assert_empty @project_state.assignable_users
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

    test 'should notify cas manager and access approvers on update to approved' do
      project = create_cas_project(project_purpose: 'test')
      project.reload_current_state

      notifications = Notification.where(title: 'Access Approval Status Updated')
      # Should not send out notifications for changes when not approved or rejected
      assert_no_difference 'notifications.count' do
        project.transition_to!(workflow_states(:submitted))
      end

      assert_difference 'notifications.count', 4 do
        project.transition_to!(workflow_states(:access_approver_approved))
      end

      assert_equal notifications.last.body, "CAS application #{project.id} - Access approval status " \
                                            "has been updated to 'Access Approver Approved'.\n\n"
    end

    test 'should notify cas manager and access approvers on update to rejected' do
      project = create_cas_project(project_purpose: 'test')
      project.reload_current_state

      notifications = Notification.where(title: 'Access Approval Status Updated')
      # Should not send out notifications for changes when not approved or rejected
      assert_no_difference 'notifications.count' do
        project.transition_to!(workflow_states(:submitted))
      end

      assert_difference 'notifications.count', 4 do
        project.transition_to!(workflow_states(:access_approver_rejected))
      end

      assert_equal notifications.last.body, "CAS application #{project.id} - Access approval status " \
                                            "has been updated to 'Access Approver Rejected'.\n\n"
    end

    test 'should notify user on update to approved' do
      project = create_cas_project(project_purpose: 'test',
                               owner: users(:no_roles))
      project.reload_current_state

      notifications = Notification.where(title: 'CAS Access Approved')
      # Should not send out notifications for changes when not approved
      assert_no_difference 'notifications.count' do
        project.transition_to!(workflow_states(:submitted))
      end

      assert_difference 'notifications.count', 1 do
        project.transition_to!(workflow_states(:access_approver_approved))
      end

      assert_equal notifications.last.body, 'Your CAS access has been approved for application ' \
                                            "#{project.id}. You will receive a further " \
                                            "notification once your account has been updated.\n\n"
    end

    test 'should notify user on update to rejected' do
      project = create_cas_project(project_purpose: 'test',
                               owner: users(:no_roles))
      project.reload_current_state

      notifications = Notification.where(title: 'CAS Access Rejected')
      # Should not send out notifications for changes when not approved
      assert_no_difference 'notifications.count' do
        project.transition_to!(workflow_states(:submitted))
        project.transition_to!(workflow_states(:access_approver_rejected))
      end

      assert_difference 'notifications.count', 1 do
        project.transition_to!(workflow_states(:rejection_reviewed))
      end

      assert_equal notifications.last.body, 'Your CAS access has been rejected for ' \
                                            "application #{project.id}.\n\n"
    end

    test 'should notify user on update to access granted' do
      project = create_cas_project(project_purpose: 'test',
                               owner: users(:no_roles))
      project.reload_current_state

      notifications = Notification.where(title: 'CAS Access Granted')
      # Should not send out notifications for changes when not access_granted
      assert_no_difference 'notifications.count' do
        project.transition_to!(workflow_states(:submitted))
      end

      assert_difference 'notifications.count', 1 do
        # This will auto-transition to access granted
        project.transition_to!(workflow_states(:access_approver_approved))
      end

      assert_equal notifications.last.body, 'CAS access has been granted for your account based ' \
                                            "on application #{project.id}.\n\n"
    end

    test 'should notify cas manager on update to access granted' do
      project = create_cas_project(project_purpose: 'test')
      project.reload_current_state

      notifications = Notification.where(title: 'CAS Access Status Updated')
      # Should not send out notifications for changes when not access_granted
      assert_no_difference 'notifications.count' do
        project.transition_to!(workflow_states(:submitted))
      end

      assert_difference 'notifications.count', 2 do
        # This will auto-transition to access granted
        project.transition_to!(workflow_states(:access_approver_approved))
      end

      assert_equal notifications.last.body, "CAS application #{project.id} - Access has been granted " \
                                            'by the helpdesk and the applicant now has CAS ' \
                                            "access.\n\n"
    end

    test 'should notify cas access approver on update to submitted' do
      project = create_cas_project(project_purpose: 'test')
      project.reload_current_state

      notifications = Notification.where(title: 'CAS Application Requires Access Approval')

      assert_difference 'notifications.count', 2 do
        project.transition_to!(workflow_states(:submitted))
      end

      assert_equal notifications.last.body, "CAS application #{project.id} - Access approval is " \
                                            "required.\n\n"

      assert_no_difference 'notifications.count' do
        project.transition_to!(workflow_states(:access_approver_approved))
      end
    end

    test 'should notify cas dataset approver at submitted for project with their dataset' do
      one_dataset_project = create_cas_project(owner: users(:no_roles))
      project_dataset = ProjectDataset.new(dataset: Dataset.find_by(name: 'Extra CAS Dataset One'),
                                           terms_accepted: true)
      one_dataset_project.project_datasets << project_dataset
      ProjectDatasetLevel.create(access_level_id: 1, expiry_date: Time.zone.today + 1.week,
                                 project_dataset_id: project_dataset.id)

      notifications = Notification.where(title: 'CAS Application Requires Dataset Approval')

      # should only send to the 2 dataset approvers with grant for this dataset
      assert_difference 'notifications.count', 2 do
        one_dataset_project.transition_to!(workflow_states(:submitted))
      end

      assert_equal notifications.last.body, "CAS application #{one_dataset_project.id} - Dataset " \
                                            "approval is required.\n\n"

      # Should not send out notifications for changes when not submitted
      assert_no_difference 'notifications.count' do
        one_dataset_project.transition_to!(workflow_states(:access_approver_approved))
      end

      two_dataset_project = create_cas_project(owner: users(:no_roles))
      project_dataset = ProjectDataset.new(dataset: Dataset.find_by(name: 'Extra CAS Dataset One'),
                                           terms_accepted: true)
      two_dataset_project.project_datasets << project_dataset
      ProjectDatasetLevel.create(access_level_id: 1, expiry_date: Time.zone.today + 1.week,
                                 project_dataset_id: project_dataset.id)
      project_dataset = ProjectDataset.new(dataset: Dataset.find_by(name: 'Extra CAS Dataset Two'),
                                           terms_accepted: true)
      two_dataset_project.project_datasets << project_dataset
      ProjectDatasetLevel.create(access_level_id: 1, expiry_date: Time.zone.today + 1.week,
                                 project_dataset_id: project_dataset.id)

      # should only send to dataset approvers with grant for either of these 2 datasets
      assert_difference 'notifications.count', 3 do
        two_dataset_project.transition_to!(workflow_states(:submitted))
      end

      assert_equal notifications.last.body, "CAS application #{two_dataset_project.id} - Dataset " \
                                            "approval is required.\n\n"

      no_dataset_project = create_cas_project(owner: users(:no_roles))
      no_dataset_project.reload_current_state

      # should not send to dataset approvers if there are no datasets
      assert_no_difference 'notifications.count' do
        no_dataset_project.transition_to!(workflow_states(:submitted))
      end

      refute_equal notifications.last.body, "CAS application #{no_dataset_project.id} - Dataset " \
                                            "approval is required.\n\n"
    end

    test 'should notify cas manager when project reaches submitted' do
      project = create_cas_project(project_purpose: 'test')
      project.reload_current_state

      notifications = Notification.where(title: 'CAS Application Submitted')

      assert_difference 'notifications.count', 2 do
        project.transition_to!(workflow_states(:submitted))
      end

      assert_equal notifications.last.body, "CAS project #{project.id} has been submitted.\n\n"

      assert_no_difference 'notifications.count' do
        project.transition_to!(workflow_states(:access_approver_approved))
      end
    end

    test 'should notify user on account closure' do
      project = create_cas_project(project_purpose: 'test',
                               owner: users(:no_roles))
      project.reload_current_state

      notifications = Notification.where(title: 'CAS Account Closed')

      assert_no_difference 'notifications.count' do
        project.transition_to!(workflow_states(:submitted))
        project.transition_to!(workflow_states(:access_approver_approved))
      end

      assert_difference 'notifications.count', 1 do
        project.transition_to!(workflow_states(:account_closed))
      end

      assert_no_difference 'notifications.count' do
        project.transition_to!(workflow_states(:draft))
      end

      assert_equal notifications.last.body, 'Your CAS account has been closed. If you still ' \
                                            'require access please re-apply using your existing ' \
                                            "application by clicking the 'return to draft' " \
                                            "button.\n\n"
    end

    test 'should notify cas manager on account closure' do
      project = create_cas_project(project_purpose: 'test', owner: users(:no_roles))

      notifications = Notification.where(title: 'CAS Account Has Closed')

      assert_no_difference 'notifications.count' do
        project.transition_to!(workflow_states(:submitted))
        project.transition_to!(workflow_states(:access_approver_approved))
      end

      assert_difference 'notifications.count', 2 do
        project.transition_to!(workflow_states(:account_closed))
      end

      assert_no_difference 'notifications.count' do
        project.transition_to!(workflow_states(:draft))
      end

      assert_equal notifications.last.body, "CAS account #{project.id} has been closed.\n\n"
    end

    test 'should auto-transition cas application from ACCESS_APPROVER_APPROVED to ACCESS_GRANTED' do
      # TODO: will need updating when script to generate access is added
      application = create_cas_project(owner: users(:no_roles))

      application.transition_to!(workflow_states(:submitted))
      application.transition_to!(workflow_states(:access_approver_approved))

      assert_equal application.current_state, workflow_states(:access_granted)
    end
  end
end
