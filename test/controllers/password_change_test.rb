require 'test_helper'

# Tests a users ability to change their password, once they're already logged in.
class PasswordChangeTest < ActionDispatch::IntegrationTest
  test 'should be unable to change password when not logged in' do
    get change_password_path
    assert_redirected_to new_user_session_path
  end

  test 'should be able to change password providing current password' do
    user = users(:standard_user_one_team)
    sign_in(user)

    post change_password_path, params: {
      user: {
        current_password:      'Password1*',
        password:              'New_password1*',
        password_confirmation: 'New_password1*'
      }
    }

    assert_redirected_to root_url
    assert_equal I18n.t('devise.registrations.updated'), flash[:notice]
    assert user.reload.valid_password?('New_password1*'), 'password should have updated'
  end

  test 'should be unable to change password without providing current password' do
    user = users(:standard_user_one_team)
    sign_in(user)

    post change_password_path, params: {
      user: {
        current_password:      'not_password',
        password:              'new_password',
        password_confirmation: 'new_password'
      }
    }

    assert_response :success
    assert user.reload.valid_password?('Password1*'), 'password should not have updated'
  end

  test 'should be unable to change password if passwords do not match' do
    user = users(:standard_user_one_team)
    sign_in(user)

    post change_password_path, params: {
      user: {
        current_password:      'Password1*',
        password:              'new_password',
        password_confirmation: 'not_password'
      }
    }

    assert_response :success
    assert user.reload.valid_password?('Password1*'), 'password should not have updated'
  end
end
