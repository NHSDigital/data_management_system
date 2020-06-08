require 'test_helper'

# Tests the ability for a user to reset their password via an email token -
# Spec override - admin to send password reset
class NotificationUserTest < ActionDispatch::IntegrationTest
  test 'Should not trigger notifications if fails login with incorrect password' do
    visit new_user_session_path
    initial_notification_count = Notification.count
    fill_in 'Username', with: 'standarduser'
    fill_in 'Password', with: 'WRONGPASSWORD'
    find_button('Log in').click
    assert Notification.count, initial_notification_count

    # lock out account
    fill_in 'Password', with: 'WRONGPASSWORD'
    find_button('Log in').click
    assert Notification.count, initial_notification_count

    assert_difference('Notification.count', 1) do
      fill_in 'Password', with: 'WRONGPASSWORD'
      find_button('Log in').click
    end
    assert Notification.last.title.include? 'User has entered wrong password 3 times'

    # Unlocking account sends a more useful notification
    assert_difference('Notification.count', 1) do
      users(:standard_user).update_attribute(:z_user_status, ZUserStatus.find_by(name: 'Active'))
    end
    assert Notification.last.title.include? 'User has been unlocked'
  end

  test 'Existing standard user update send notification' do
    assert_difference('Notification.count', 2) do
      users(:standard_user).update_attribute(:first_name, 'change_name')
      users(:standard_user).update_attribute(:first_name, 'standard')
    end
  end

  test 'Saving User with not changes does not create a notification' do
    assert_difference('Notification.count', 0) do
      u = User.first
      u.save
    end
  end
end
