require 'test_helper'

class HomeControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:standard_user2)
    sign_in(@user)
  end

  test 'should get index' do
    get home_index_path
    assert_response :success
  end
end
