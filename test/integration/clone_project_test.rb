require 'test_helper'

class CloneProjectTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:standard_user1)
    @team = teams(:team_two)
    login_and_accept_terms(@user)
  end

  test 'can clone a project' do
    navigate_to_clone_project
    assert page.has_content? 'Duplicating'

    assert_difference('Project.count') do
      fill_in 'project_name', with: 'Clone of Existing Project'
      fill_in_project_dates
      click_button('Save')

      assert page.has_content?('Clone of Existing Project')
      assert page.has_content?('New')
    end
  end

  test 'clone project form always shows fields required to clone only' do
    navigate_to_clone_project
    assert page.has_content? 'Duplicating'
    # fill in with existing name, expect uniqueness error
    # within_modal(remain: true) do
      fill_in 'project_name', with: projects(:one).name.to_s
      fill_in_project_dates
      find_button('Save').click
    # end
    assert page.has_content? 'Name already being used by this Team'
    # other form sections still hidden after error
    assert page.has_no_content? 'End Uses'
    assert page.has_no_content? 'Data specification'

    # can input corrected name
    fill_in 'project_name', with: 'Invalid name then unique name'

    assert_difference('ProjectDataset.count', 1) do
      find_button('Save').click
    end

    assert page.has_content?('Invalid name then unique name')
    assert page.has_content?('New')
  end

  test 'clone hidden from users of certain type' do
    click_on(@user.email)
    click_on('Logout')
    @project_user = users(:standard_user2)
    login_and_accept_terms(@project_user)
    visit team_path(teams(:team_two))
    assert page.has_no_content? 'Clone'
  end

  private

  def navigate_to_clone_project
    # TODO: flakeiness with existing senior_user_id column. It should be replaced with the owner
    # grant logic
    projects(:one).update_attribute(:senior_user_id, users(:standard_user1).id)
    visit team_path(teams(:team_two))
    find_link('Projects').click
    find_link('Clone').click
  end

  def fill_in_project_dates
    fill_in 'project_start_data_date', with: '01/01/2018'
    find('label', text: 'Start Date').click

    fill_in 'project_end_data_date', with: (Date.current + 1.year).strftime('%d/%m/%Y')
    find('label', text: 'End Date').click
  end
end
