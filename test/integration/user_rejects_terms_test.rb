require 'test_helper'

# Tests that accounts are locked after a number of failed login attempts
class UserRejectsTermsTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:standard_user_one_team)
  end

  test 'sign in and reject terms' do
    sign_in @user
    visit terms_and_conditions_path
    click_on 'Reject'
    assert page.has_content?('You have 2 attempts to approve the terms and then your account will be locked')
    sign_in @user
    visit terms_and_conditions_path
    click_on 'Reject'
    assert page.has_content?('You have 1 attempts to approve the terms and then your account will be locked')
    sign_in @user
    visit terms_and_conditions_path
    click_on 'Reject'

    assert page.has_text? 'You are logging in as Standard Userone'
    assert page.has_text? 'You have failed to accept the Data Management System Terms and Conditions'
    assert page.has_text? 'If this was done in error please contact Data Management System administrator'
    assert page.has_content?('Welcome to the Data Management System')

    @user.reload
    refute_nil @user.locked_at?
    assert @user.z_user_status_id == ZUserStatus.where(name: 'Lockout').first.id
  end
end
