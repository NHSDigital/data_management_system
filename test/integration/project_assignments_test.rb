require 'test_helper'

class ProjectAssignmentsTest < ActionDispatch::IntegrationTest
  def setup
    @project = projects(:test_application)
  end

  test 'can change temporally assigned user (as an application manager)' do
    user_one = users(:application_manager_one)
    user_two = users(:application_manager_two)

    sign_in(user_one)

    visit project_path(@project)

    within('#project_header') do
      assert has_select?('Assigned User')

      within('#new_project_state_assignment') do
        select user_two.full_name, from: 'Assigned User'
        click_button 'Apply'
      end
    end

    assert_equal project_path(@project), current_path
    assert has_text?('Project assigned successfully')
    assert has_select?('Assigned User')
    assert has_no_selector?('dt', text: 'Assigned User')
  end

  test 'can change temporally assigned user (as regular user)' do
    @project.current_project_state.assign_to!(user: @project.owner)

    new_assignee = users(:application_manager_two)

    sign_in(@project.owner)

    visit project_path(@project)

    within('#project_header') do
      assert has_select?('Assigned User')

      within('#new_project_state_assignment') do
        select new_assignee.full_name, from: 'Assigned User'
        click_button 'Apply'
      end
    end

    assert has_no_select?('Assigned User')
    assert has_selector?('dt', text: 'Assigned User')
    assert find('dt', text: 'Assigned User').has_sibling?('dd', text: new_assignee.full_name)
  end
end
