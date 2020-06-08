require 'test_helper'
require 'project_helper'

class AddDataEndUsersToProjectTest < ActionDispatch::IntegrationTest
  # this test is for a modal version of 'add data item' currently not in use
  test 'user can add a new data end user' do
    login_and_accept_terms(users(:new_senior_user))
    visit project_path(projects(:new_project))
    click_link('Users')
    click_link('Add End User')
    assert_difference('ProjectDataEndUser.count', 1) do
      within_modal do
        fill_in 'First name', with: 'Jon'
        fill_in 'Last name', with: 'Smith'
        fill_in 'Email', with: 'Jon@smith.com'
        select 'Yes', from: 'project_data_end_user_ts_cs_accepted'
        click_button 'Save'
      end
      assert page.has_content?('Jon@smith.com')
      assert ProjectDataEndUser.find_by(email: 'Jon@smith.com').ts_cs_accepted
    end
  end

  test 'contributor can add and remove data end user' do
    project = projects(:new_project)
    login_and_accept_terms(users(:new_senior_user))
    visit project_path(project)
    click_link('Users')
    click_link('Add End User')
    assert_difference('ProjectDataEndUser.count', 1) do
      within_modal do
        fill_in_end_user
      end
      assert page.has_content?('Jon@smith.com')
    end
    assert_difference('ProjectDataEndUser.count', -1) do
      delete_end_user
      assert page.has_no_content?('Jon@smith.com')
    end
  end

  test 'owner can add and remove data end user' do
    project = projects(:new_project)
    login_and_accept_terms(project.owner)
    visit project_path(project)
    click_link('Users')
    click_link('Add End User')
    assert_difference('ProjectDataEndUser.count', 1) do
      within_modal do
        fill_in_end_user
      end
      assert page.has_content?('Jon@smith.com')
    end
    assert_difference('ProjectDataEndUser.count', -1) do
      delete_end_user
      assert page.has_no_content?('Jon@smith.com')
    end
  end

  # TODO:
  test 'read only cannot add and remove data end user' do
  end

  def fill_in_end_user
    fill_in 'First name', with: 'Jon'
    fill_in 'Last name', with: 'Smith'
    fill_in 'Email', with: 'Jon@smith.com'
    select 'No', from: 'project_data_end_user_ts_cs_accepted'
    click_button 'Save'
  end

  def delete_end_user
    accept_prompt do
      user_row = page.find('#data-end-users-table').find('tr', text: 'Jon@smith.com')
      user_row.click_link('delete_project_data_project_data_end_user')
    end
  end
end
