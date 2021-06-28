require 'test_helper'

class ErrorViewingTest < ActionDispatch::IntegrationTest
  test 'should not be accessible to unauthenticated users' do
    visit ndr_error.error_fingerprints_path
    assert_equal new_user_session_path, current_path
  end

  test 'should not be accessible to unauthorised users' do
    user = users(:standard_user)
    user.grants.where(roleable: SystemRole.fetch(:developer)).destroy_all

    sign_in user

    visit ndr_error.error_fingerprints_path
    assert_equal root_path, current_path
  end

  test 'should be accessible to authorised users' do
    user = users(:standard_user)
    user.grants.create!(roleable: SystemRole.fetch(:developer))

    sign_in user

    visit ndr_error.error_fingerprints_path
    assert_equal ndr_error.error_fingerprints_path, current_path
  end
end
