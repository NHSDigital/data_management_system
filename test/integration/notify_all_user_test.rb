require 'test_helper'

class NotifyAllUserTest < ActionDispatch::IntegrationTest
  def setup
    @admin = users(:admin_user)
    @odr = users(:odr_user)
    @standard = users(:standard_user)
  end

  test 'admin can create a notifications to go to all users' do
    login_and_accept_terms(@admin)
    create_notification(title: 'new admin notification', admin_users: true)
    visit notifications_path
    assert page.has_content?('Message all users')
    click_link 'Message all users'
    assert_difference('Notification.count', 1) do
      within_modal do
        fill_in 'Title', with: 'Title of email to go to all users'
        fill_in 'Message', with: 'Message email to go to all users'
        click_button 'Save'
      end
      assert has_no_selector?('#modal', visible: true)
      assert page.has_content?('All users sucessfully messaged')
    end
    assert_equal Notification.last.user_notifications.count, User.in_use.count
  end

  test 'odr user cannot create notifications to go to all users' do
    login_and_accept_terms(@odr)
    create_notification(title: 'new admin notification', admin_users: true)
    visit notifications_path
    assert page.has_no_content?('Message all users')

  end

  test 'standard user cannot create notifications to go to all users' do
    login_and_accept_terms(@standard)
    create_notification(title: 'new admin notification', admin_users: true)
    visit notifications_path
    assert page.has_no_content?('Message all users')
  end

end
