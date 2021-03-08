require 'test_helper'

class WorkflowTest < ActionDispatch::IntegrationTest
  test 'should prompt for Yubikey when performing a protected transition' do
    Workflow::Transition.update_all(requires_yubikey: true)

    project = projects(:one)

    project.update(details_approved: true, members_approved: true, legal_ethical_approved: true)
    project.project_nodes.update_all(approved: true)

    sign_in users(:odr_user)

    visit terms_and_conditions_path
    click_on 'Accept'

    visit project_path(project)
    assert_equal project_path(project), current_path

    assert_no_difference -> { project.project_states.count } do
      accept_prompt do
        click_button 'Approve'
      end

      assert has_text? 'Authentication Required'
    end
  end

  test 'should not prompt for Yubikey when performing an unprotected transition' do
    Workflow::Transition.update_all(requires_yubikey: false)

    project = projects(:one)

    project.update(details_approved: true, members_approved: true, legal_ethical_approved: true)
    project.project_nodes.update_all(approved: true)

    sign_in users(:odr_user)

    visit terms_and_conditions_path
    click_on 'Accept'

    visit project_path(project)
    assert_equal project_path(project), current_path

    assert_difference -> { project.project_states.count } do
      accept_prompt do
        click_button 'Approve'
      end

      within('#project_status') do
        assert has_text?('APPROVED')
      end

      assert has_no_text? 'Authentication Required'
    end
  end
end
