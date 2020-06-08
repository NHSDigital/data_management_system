require 'test_helper'

class SmokeTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:standard_user_one_team)
    @admin = users(:admin_user)
    @deleted_user = users(:deleted_user)
  end

  test 'sign in and accept terms' do
    sign_in @user
    visit terms_and_conditions_path
    click_on 'Accept'
    assert page.has_content?('Notifications')
    visit terms_and_conditions_path
    assert page.has_content?('Terms and Conditions have been accepted')
  end

  test 'sign in and reject terms' do
    sign_in @user
    visit terms_and_conditions_path
    click_on 'Reject'
    assert page.has_content?('You have 2 attempts to approve the terms and then your account will be locked')
    assert page.has_content?('Welcome to the Data Management System')
  end

  test 'users flagged as deleted can no longer log in' do
    deleted_user_username = @deleted_user.username

    visit new_user_session_path

    assert page.has_content?('Welcome to the Data Management System')
    fill_in 'Username',    with: deleted_user_username
    fill_in 'Password', with: 'Password1*'
    click_button 'Log in'
    assert page.has_content? <<~FLASH
      Your account is not activated yet.
    FLASH
  end
end
