require 'test_helper'
require 'project_helper'

class ManageDatasetTest < ActionDispatch::IntegrationTest
  def setup
    @admin = users(:admin_user)
    login_and_accept_terms(@admin)
  end

  test 'can access dataset admin page' do
    visit datasets_path
    assert page.has_content? 'Listing Datasets'
    assert page.has_content? 'Deaths Gold Standard'
  end

  test 'can create and destroy a dataset' do
    visit team_path(teams(:mbis))
    within('#team_show_tabs') do
      click_on 'Datasets'
    end
    page.find_link('Add New Dataset').click
    fill_in 'Name', with: 'new dataset'
    fill_in 'Title', with: 'new title'
    click_button 'Save'
    assert page.has_content? 'new title'
  end
end
