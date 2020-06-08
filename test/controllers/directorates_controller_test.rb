require 'test_helper'

class DirectoratesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:standard_user_one_team)
    @admin = users(:admin_user)
  end

  test 'should not get index unless current user is admin' do
    refute @user.administrator?
    sign_in(@user)
    get directorates_url
    assert_redirected_to root_url
  end

  test 'should get index when current user is admin' do
    sign_in(@admin)
    get directorates_url
    assert_response :success
  end

end
