require 'test_helper'

# Tests that accounts are locked after a number of failed login attempts
class ForgotPasswordTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:standard_user_one_team)
  end

  test 'user can request new password process' do
    visit root_path
    click_on 'Forgot your password?'
    fill_in 'Email', with: @user.email
    click_on 'Send me reset password instructions'

    assert page.has_text? 'You are logging in as Standard Userone'
    assert page.has_text? 'You have forgotten your password'
    assert page.has_text? 'You will be contacted by email with details of how to reset your account'

    assert_equal Notification.last.title, 'User has forgotten password'
  end

  test 'unknown user cannot request a new password' do
    visit root_path
    click_on 'Forgot your password?'
    fill_in 'Email', with: 'some@random.net'
    click_on 'Send me reset password instructions'
    assert page.has_content?('Could not find user account')
  end
end
