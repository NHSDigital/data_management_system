require 'test_helper'

# Tests the ability for a user to reset their password via an email token -
# Spec override - admin to send password reset
class PasswordResetTest < ActionDispatch::IntegrationTest
  test 'should be able to reset password via email token' do
    standard_user = users(:standard_user)
    standard_user.send_reset_password_instructions
    open_email(standard_user.email) # sets `current_email`
    assert_equal 'Reset password instructions', current_email.subject

    current_email.click_link 'Change my password'

    assert find('h3').has_content?('Change your password')

    fill_in 'New password',         with: 'Standard_user_new_password1*'
    fill_in 'Confirm new password', with: 'Standard_user_new_password1*'

    click_button 'Change my password'

    assert page.has_content? <<~FLASH
      Your password has been changed successfully. You are now signed in.
    FLASH
  end

  test 'should still be able to sign in after reset token emailed' do
    standard_user = users(:standard_user)
    standard_user.send_reset_password_instructions
    open_email(standard_user.email) # sets `current_email`
    assert_equal 'Reset password instructions', current_email.subject
    current_email.click_link 'Change my password'

    visit new_user_session_path

    assert page.has_content?('Welcome to the Data Management System')
    fill_in 'Username',    with: standard_user.username
    fill_in 'Password', with: 'Password1*'
    click_button 'Log in'

    assert page.has_content? <<~FLASH
      Signed in successfully.
    FLASH
  end
end
