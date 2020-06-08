require 'test_helper'

class CanManageDatasetVersionsTest < ActionDispatch::IntegrationTest
  def setup
    @admin = users(:admin_user)
    @dataset_manager = users(:team_dataset_manager)
  end

  test 'admin can create and destroy a dataset version' do
    login_and_accept_terms(@admin)
    visit datasets_path
    add_version
  end

  test 'dataset_manager can add version to relative team' do
    login_and_accept_terms(@dataset_manager)
    visit datasets_path
    add_version

    visit team_path(teams(:ncras))
    within('#team_show_tabs') do
      click_on 'Datasets'
    end
    assert has_no_content? 'Add New Dataset'
    assert has_no_content? 'Add New Version'
  end

  private
  
  def add_version
    assert has_content? 'Listing Datasets'
    assert has_content? 'Deaths Gold Standard'

    assert has_no_content? 'Add New Version'
    visit team_path(teams(:mbis))
    within('#team_show_tabs') do
      click_on 'Datasets'
    end
    dataset_row = find('#datasets').find('tr', text: 'Deaths Gold Standard')
    within(dataset_row) do
      find_link('Add New Version').click
    end

    fill_in 'Semantic Version', with: '2.0'
    click_button 'Save'

    assert has_content? '1.0'
    assert has_content? '2.0'

    within(dataset_row) do
      accept_prompt do
        find_link('Delete').click
      end

      assert has_no_content? '2.0'
    end
  end
end
