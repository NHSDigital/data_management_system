require 'test_helper'

class ProjectAssignmentsTest < ActionDispatch::IntegrationTest
  def setup
    @project = projects(:test_application)
  end

  test 'can change temporally assigned user' do
    user_one = users(:application_manager_one)
    user_two = users(:application_manager_two)

    # Force project into a state that is temporally reassignable...
    @project.project_states.build do |project_state|
      project_state.state = workflow_states(:dpia_review)
      project_state.assignments.build(assigned_user: user_one)

      project_state.save!(validate: false)
    end

    sign_in(user_one)

    visit project_path(@project)

    within('#project_header') do
      assert has_select?('Assigned User')

      within(find_field('Assigned User').ancestor('form')) do
        select user_two.full_name, from: 'Assigned User'
        click_button 'Apply'
      end
    end

    assert_equal project_path(@project), current_path
    assert has_text?('Project assigned successfully')
    assert has_no_select?('Assigned User')
    assert has_selector?('dt', text: 'Assigned User')
    assert find('dt', text: 'Assigned User').has_sibling?('dd', text: user_two.full_name)
  end
end
