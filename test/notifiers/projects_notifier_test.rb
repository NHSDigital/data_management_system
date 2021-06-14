require 'test_helper'

class ProjectsNotifierTest < ActiveSupport::TestCase
  test 'should generate project assignment Notifications' do
    project = projects(:one)
    project.assigned_user = users(:application_manager_one)

    assert_difference -> { Notification.where(title: 'Project Assignment').count } do
      assert_difference -> { UserNotification.count } do
        ProjectsNotifier.project_assignment(project: project, assigned_to: project.assigned_user)
      end
    end

    # assert_equal project.assigned_user, UserNotification.order(:created_at).last.user
  end

  test 'should generate project awaiting assignment Notifications' do
    project = projects(:one)
    project.assigned_user = nil

    assert_difference -> { Notification.where(title: 'Project Awaiting Assignment').count } do
      assert_difference -> { UserNotification.count }, User.odr_users.count do
        ProjectsNotifier.project_awaiting_assignment(project: project)
      end
    end
  end

  test 'should not generate project awaiting assignment Notifications when not odr or mbis' do
    project = build_project(project_type: project_types(:cas), assigned_user: nil)

    assert_no_difference -> { Notification.where(title: 'Project Awaiting Assignment').count } do
      assert_no_difference -> { UserNotification.count } do
        ProjectsNotifier.project_awaiting_assignment(project: project)
      end
    end
  end
end
