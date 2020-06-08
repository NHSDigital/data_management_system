require 'test_helper'

class NotificationTest < ActiveSupport::TestCase
  test 'admin notification gets sent to admin users' do
    notification = create_notification(admin_users: true)
    assert_equal notification.users.count, 2
    notification.user_notifications.each do |un|
      assert_equal un.status, 'new'
      assert un.user.administrator?
    end
  end

  test 'odr notification gets sent to odr users' do
    notification = create_notification(odr_users: true)
    assert_equal notification.users.count, 2
    notification.user_notifications.each do |un|
      assert_equal un.status, 'new'
      assert un.user.odr?
    end
  end

  test 'single user notification gets sent to user' do
    notification = create_notification(user_id: users(:standard_user).id)
    assert_equal notification.users.count, 1
    assert_equal notification.users.first.email, 'standard@phe.gov.uk'
  end

end
