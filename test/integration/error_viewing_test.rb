require 'test_helper'

class ErrorViewingTest < ActionDispatch::IntegrationTest
  test 'should not be accessible to unauthenticated users' do
    visit ndr_error.error_fingerprints_path
    assert_equal new_user_session_path, current_path
  end

  test 'should not be accessible to unauthorised users' do
    sign_in users(:standard_user)

    User.any_instance.stubs(:can?).
      with(:read, :ndr_errors).
      returns(false)

    visit ndr_error.error_fingerprints_path
    assert_equal root_path, current_path
  end

  test 'should be accessible to authorised users' do
    sign_in users(:standard_user)

    User.any_instance.stubs(:can?).
      with(:read, :ndr_errors).
      returns(true)

    visit ndr_error.error_fingerprints_path
    assert_equal ndr_error.error_fingerprints_path, current_path
  end
end
