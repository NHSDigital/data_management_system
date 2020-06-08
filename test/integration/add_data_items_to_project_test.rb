require 'test_helper'
require 'project_helper'

class AddDataItemsToProjectTest < ActionDispatch::IntegrationTest
=begin
  # this test is for a modal version of 'add data item' currently not in use
  test 'user can add a new data item' do
    login_and_accept_terms(users(:new_senior_user))
    visit project_path(projects(:new_project))
    click_link('Data Items')
    click_link('Add')
    assert_difference('ProjectComment.count', 1) do
      within_modal do
        fill_in 'Justification', with: 'I really want this data item'
        select 'DIR: surname: gold surname',        from: 'Item'
        click_button 'Save'
      end
    end
    assert page.has_content?('gold surname')
  end
=end
  test 'contributor can remove data item' do
    project = projects(:new_project)
    login_and_accept_terms(users(:new_senior_user))
    visit project_path(project)
    click_link('Data Items')
    assert page.has_content?('DOBYR')
    assert_difference('project.project_nodes.count', -1) do
      remove_item
      assert page.has_no_content?('DOBYR')
    end
  end

  test 'owner can remove data item' do
    project = projects(:new_project)
    login_and_accept_terms(project.owner)
    visit project_path(project)
    click_link('Data Items')
    assert page.has_content?('DOBYR')
    assert_difference('project.project_nodes.count', -1) do
      remove_item
      assert page.has_no_content?('DOBYR')
    end
  end

  # TODO: read only cannot

  private

  def remove_item
    accept_prompt do
      dob_row = page.find('#project-data-items').find('tr', text: 'DOBYR')
      dob_row.click_link('delete_project_data_item')
    end
  end
end
