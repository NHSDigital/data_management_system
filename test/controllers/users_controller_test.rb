require 'test_helper'

class UsersControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:standard_user_one_team)
    @admin = users(:admin_user)
  end

  test 'should get index for standard user' do
    sign_in(@user)
    get users_url
    assert_response :success
  end

  test 'should get index when current user is admin' do
    sign_in(@admin)
    get users_url
    assert_response :success
  end

  test 'should only show current user unless current user is admin' do
    refute @user.administrator?
    sign_in(@user)
    get user_url(@user)
    assert_response :success

    get user_url(@admin)
    assert_redirected_to root_url
  end

  test 'should show user when current user is admin' do
    sign_in(@admin)
    get user_url(@user)
    assert_response :success
  end

  test 'should not get new user unless current user is admin' do
    refute @user.administrator?
    sign_in(@user)
    get new_user_url
    assert_redirected_to root_url
  end

  test 'should get new user when current user is admin' do
    sign_in(@admin)
    get new_user_url
    assert_response :success
  end

  test 'should not get edit user unless current user is admin' do
    refute @user.administrator?
    sign_in(@user)
    get edit_user_url(@user)
    assert_redirected_to root_url
  end

  test 'should get edit user when current user is admin' do
    sign_in(@admin)
    get edit_user_url(@user)
    assert_response :success
  end

  # TODO: check how passwords will be created and distributed to new users
  # test 'should create user' do
  #   sign_in @admin
  #
  #   assert_difference('User.count') do
  #     post users_url, params: {
  #       user: {
  #         first_name: 'BOB', last_name: 'FOSSIL',
  #         email: 'bob@fossil.com', location: 'Cambridge',
  #         z_user_status_id: 1
  #       }
  #     }
  #   end
  #
  #   assert_redirected_to user_url(User.last)
  # end

  test 'should update user' do
    sign_in(@admin)
    patch user_url(@user), params: {
      user: {
        first_name: @user.first_name, last_name: @user.last_name,
        email: @user.email, location: @user.location,
        z_user_status_id: ZUserStatus.where(name: 'Active').first.id
      }
    }
    assert_redirected_to user_url(@user)
  end

  test 'should flag user as deleted' do
    sign_in(@admin)
    assert_difference('User.in_use.count', -1) do
      delete user_url(@user)
    end

    assert_redirected_to users_url
  end

  test 'should not destroy current user' do
    sign_in(@admin)

    count_one = User.in_use.count
    delete user_url(@admin)

    count_two = User.in_use.count

    assert_equal count_two, count_one
    assert_redirected_to @admin
  end

  test 'should not destroy user who is a project senior user' do
    sign_in(@admin)
    project_senior_user = users(:standard_user1)

    assert_no_difference('User.count') do
      delete user_url(project_senior_user)
    end

    assert_redirected_to project_senior_user
  end
end
