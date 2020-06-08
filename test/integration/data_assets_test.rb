require 'test_helper'

class DataAssetsTest < ActionDispatch::IntegrationTest
  def setup
    @admin = users(:admin_user)
    login_and_accept_terms(@admin)
  end

  test 'should be able to search data assets by name or title' do
    visit data_assets_path

    within('#search-form') do
      fill_in 'search[name]', with: 'dummy'
      click_button :submit
    end

    assert_equal data_assets_path, current_path
    within('table') do
      assert has_no_text?('Birth')
    end

    within('#search-form') do
      fill_in 'search[name]', with: 'bir'
      click_button :submit
    end

    within('table') do
      assert has_text?('Birth')
    end
  end
end
