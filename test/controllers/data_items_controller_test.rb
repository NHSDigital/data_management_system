require 'test_helper'

class DataItemsControllerTest < ActionDispatch::IntegrationTest
  def setup
    User.any_instance.stubs(administrator?: true)
    @admin = users(:admin_user)
  end

  test 'show item form' do
    sign_in(@admin)
    node = Dataset.find_by(name: 'Births Gold Standard').dataset_versions.
           last.data_items.find_by(name: 'DOB')
    get data_item_url node
    assert_response :success
  end
end
