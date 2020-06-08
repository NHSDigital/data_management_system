require 'test_helper'

class NotificationsControllerTest < ActionDispatch::IntegrationTest
  def setup
    Notification.any_instance.stubs(admin_user: true)
    sign_in(users(:admin_user))
  end

  test 'should get index' do
    get notifications_url
    assert_response :success
  end

  test 'should show unread notifications' do
    get notifications_url, params: { mailbox: 'new' }
    assert_response :success
  end

  test 'should show deleted notifications' do
    get notifications_url, params: { mailbox: 'deleted' }
    assert_response :success
  end
end
