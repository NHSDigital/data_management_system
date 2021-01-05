require 'test_helper'

class ProjectAmendmentsTest < ActionDispatch::IntegrationTest
  def setup
    sign_in users(:application_manager_one)
  end

  test 'should be able to view the list of amendments' do
    project   = projects(:test_application)
    amendment = create_amendment(project)

    visit project_path(project)
    click_on('Amendments')

    within('#projectAmendments') do
      dom_id = "\#project_amendment_#{amendment.id}"

      assert has_no_link?(href: new_project_project_amendment_path(project))
      assert has_selector?(dom_id)

      within(dom_id) do
        assert has_text?(amendment.requested_at.to_s(:ui))
        assert has_link?(href: project_amendment_path(amendment),         title: 'Details')
        assert has_no_link?(href: edit_project_amendment_path(amendment), title: 'Edit')
        assert has_no_link?(href: project_amendment_path(amendment),      title: 'Delete')
      end
    end
  end

  test 'should be able to create an amendment' do
    project = projects(:test_application)

    project.transition_to!(workflow_states(:submitted))
    project.transition_to!(workflow_states(:dpia_start))
    project.transition_to!(workflow_states(:amend))

    visit project_path(project)
    click_on('Amendments')

    click_link('New')

    fill_in('project_amendment[requested_at]', with: '27/03/2020')
    attach_file('project_amendment[upload]', file_fixture('odr_amendment_request_form-1.0.pdf'))

    assert_difference -> { project.project_amendments.count } do
      click_button('Create Amendment')

      assert_equal project_path(project), current_path
      assert has_text?('Amendment created successfully')
      assert has_selector?('#projectAmendments', visible: true)
    end
  end

  test 'should be able to update an amendment' do
    project = projects(:test_application)

    project.transition_to!(workflow_states(:submitted))
    project.transition_to!(workflow_states(:dpia_start))
    project.transition_to!(workflow_states(:amend))

    amendment = create_amendment(project)

    visit project_path(project)
    click_on('Amendments')

    click_link(href: edit_project_amendment_path(amendment))

    check('Data Flows')
    check('Duration')

    assert_changes -> { amendment.reload.labels } do
      click_button('Update Amendment')

      assert_equal project_path(project), current_path
      assert has_text?('Amendment updated successfully')
      assert has_selector?('#projectAmendments', visible: true)
    end
  end

  test 'should be able to destroy an amendment' do
    project = projects(:test_application)

    project.transition_to!(workflow_states(:submitted))
    project.transition_to!(workflow_states(:dpia_start))
    project.transition_to!(workflow_states(:amend))

    amendment = create_amendment(project)

    visit project_path(project)
    click_on('Amendments')

    assert_difference -> { project.project_amendments.count }, -1 do
      accept_prompt do
        click_link(href: project_amendment_path(amendment), title: 'Delete')
      end

      assert_equal project_path(project), current_path
    end

    assert has_text?('Amendment destroyed successfully')
    assert has_selector?('#projectAmendments', visible: true)
  end

  test 'should be able to view an amendment' do
    project   = projects(:test_application)
    amendment = create_amendment(project)

    visit project_path(project)
    click_on('Amendments')

    click_link(href: project_amendment_path(amendment), title: 'Details')
    assert_equal project_amendment_path(amendment), current_path
  end

  test 'should redirect if unauthorized' do
    sign_out users(:application_manager_one)
    sign_in  users(:standard_user)

    project   = projects(:test_application)
    amendment = create_amendment(project)

    visit edit_project_amendment_path(amendment)

    refute_equal project_amendment_path(amendment), current_path
    assert has_text?('You are not authorized to access this page.')
  end
end
