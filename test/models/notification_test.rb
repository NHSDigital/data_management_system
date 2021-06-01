require 'test_helper'

class NotificationTest < ActiveSupport::TestCase
  test 'returns a set of users to notify' do
    notification = Notification.new(title: 'Test', body: 'This is a test')

    assert_instance_of Set, notification.users_to_notify
    assert_empty notification.users_to_notify
  end

  test 'returns a set of users to notify (all users)' do
    notification = Notification.new(title: 'Test', body: 'This is a test', all_users: true)
    expected     = User.in_use.ids.to_set

    assert_equal expected, notification.users_to_notify
  end

  test 'returns a set of users to notify (admin users)' do
    notification = Notification.new(title: 'Test', body: 'This is a test', admin_users: true)
    expected     = User.administrators.ids.to_set

    assert_equal expected, notification.users_to_notify
  end

  test 'returns a set of users to notify (odr users)' do
    notification = Notification.new(title: 'Test', body: 'This is a test', odr_users: true)
    expected     = User.odr_users.ids.to_set

    assert_equal expected, notification.users_to_notify
  end

  test 'returns a set of users to notify (team users)' do
    team         = teams(:team_one)
    notification = Notification.new(title: 'Test', body: 'This is a test', team_id: team.id)
    expected     = team.users.ids.to_set

    assert_equal expected, notification.users_to_notify
  end

  test 'returns a set of users to notify (project users)' do
    project      = projects(:dummy_project)
    notification = Notification.new(title: 'Test', body: 'This is a test', project_id: project.id)
    expected     = project.users.ids.to_set

    assert_equal expected, notification.users_to_notify
  end

  test 'returns a set of users to notify (single users)' do
    user         = users(:standard_user1)
    notification = Notification.new(title: 'Test', body: 'This is a test', user_id: user.id)
    expected     = Set.new([user.id])

    assert_equal expected, notification.users_to_notify
  end

  test 'returns a set of users to exclude from notification' do
    notification = Notification.new(title: 'Test', body: 'This is a test')

    assert_instance_of Set, notification.users_not_to_notify
    assert_empty notification.users_not_to_notify
  end

  test 'excludes users from notification' do
    user         = users(:standard_user1)
    notification = Notification.new(title: 'Test', body: 'This is a test', all_users: true)

    notification.users_not_to_notify << user.id

    refute_includes notification.users_to_notify, user.id
  end

  test 'generates user notifications on create' do
    user         = users(:standard_user1)
    notification = Notification.new(title: 'Test', body: 'This is a test', user_id: user.id)

    assert_difference -> { notification.user_notifications.count } do
      notification.save!
    end
  end
end
