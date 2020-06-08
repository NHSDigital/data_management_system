require 'test_helper'

# Tests that accounts are locked after a number of failed login attempts
class AccountLockingTest < ActionDispatch::IntegrationTest
  test 'should be locked out after 3 failed login attempts' do
    username       = users(:standard_user).username
    right_password = 'Password1*'
    wrong_password = 'wordpass'

    attempt_login_with(username, wrong_password) # 1
    assert page.has_content?('Invalid Username or password.')

    attempt_login_with(username, wrong_password) # 2
    assert page.has_content?('You have one more attempt before your account is locked.')

    attempt_login_with(username, wrong_password) # 3
    assert page.has_text? 'You are logging in as Standard User'
    assert page.has_text? 'Failed to enter the correct password 3 times'
    assert page.has_text? 'Used a faulty or unauthorised Yubikey'
    assert page.has_text? 'You will be contacted by email with details of how to reset your account'

    attempt_login_with(username, right_password) # Right password, but locked
    assert page.has_content?('Your account is locked')
  end

  private

  def attempt_login_with(username, password)
    visit new_user_session_path

    fill_in 'Username',    with: username
    fill_in 'Password', with: password
    click_button 'Log in'
  end
end
