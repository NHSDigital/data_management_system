require 'test_helper'

class ProjectsNotifierTest < ActiveSupport::TestCase
  test 'should generate project assignment Notifications' do
    project = projects(:one)
    project.assigned_user = users(:application_manager_one)

    assert_difference -> { Notification.where(title: 'Project Assignment').count } do
      assert_difference -> { UserNotification.count } do
        ProjectsNotifier.project_assignment(project: project)
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
end
