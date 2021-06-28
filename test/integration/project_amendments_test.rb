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
      assert has_text?('Requested at')
      assert has_text?('Amendment approved date')

      within(dom_id) do
        assert has_text?(amendment.requested_at.to_s(:ui))
        assert has_text?(amendment.amendment_approved_date.to_s(:ui))
        assert has_link?(href: project_amendment_path(amendment),         title: 'Details')
        assert has_no_link?(href: edit_project_amendment_path(amendment), title: 'Edit')
        assert has_no_link?(href: project_amendment_path(amendment),      title: 'Delete')
      end
    end
  end

  test 'should be able to create an amendment' do
    project = projects(:test_application)
    project.first_contact_date = Date.parse('2020/03/31')

    project.transition_to!(workflow_states(:submitted))
    project.transition_to!(workflow_states(:dpia_start))
    project.transition_to!(workflow_states(:amend))

    visit project_path(project)
    click_on('Amendments')

    click_link('New')
    assert has_no_field?('project_amendment[reference]')

    fill_in('project_amendment[requested_at]', with: '27/03/2020')
    fill_in('project_amendment[amendment_approved_date]', with: '29/03/2020')
    attach_file('project_amendment[upload]', file_fixture('odr_amendment_request_form-1.0.pdf'))

    assert_difference -> { project.project_amendments.count } do
      click_button('Create Amendment')

      assert_equal project_path(project), current_path
      assert has_text?('Amendment created successfully')
      assert has_selector?('#projectAmendments', visible: true)
    end
    assert_equal 1, project.reload.amendment_number
    expected_amendment_reference = "ODR_2019_2020_#{project.id}/A1"
    assert_equal expected_amendment_reference, project.project_amendments.first.reference
  end

  test 'should be able to update an amendment' do
    project = projects(:test_application)
    project.first_contact_date = Date.parse('2020/03/31')

    project.transition_to!(workflow_states(:submitted))
    project.transition_to!(workflow_states(:dpia_start))
    project.transition_to!(workflow_states(:amend))

    amendment = create_amendment(project)
    amendment_reference = "ODR_2019_2020_#{project.id}/A1"
    assert_equal project.project_amendments.first.reference, amendment_reference
    visit project_path(project)
    click_on('Amendments')

    click_link(href: edit_project_amendment_path(amendment))
    assert has_no_field?('project_amendment[reference]')

    check('Data Flows')
    check('Duration')

    assert_changes -> { amendment.reload.labels } do
      assert_no_changes -> { amendment.reference } do
        click_button('Update Amendment')

        assert_equal project_path(project), current_path
        assert has_text?('Amendment updated successfully')
        assert has_selector?('#projectAmendments', visible: true)
      end
    end
    # should not have changed
    assert_equal project.project_amendments.first.reference, amendment_reference
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

  test 'amendments without attachments should block transition to DPIA_START' do
    project = projects(:test_application)

    project.transition_to!(workflow_states(:submitted))
    project.transition_to!(workflow_states(:dpia_start))
    project.update!(assigned_user: users(:application_manager_one))

    visit project_path(project)

    within('#project_header') do
      accept_confirm do
        click_button 'Amend'
      end
    end

    assert has_text?('This project cannot move to "DPIA" for 1 reason')
    assert has_text?('no amendment document attached')
    assert has_button?('Begin DPIA', disabled: true)

    click_link 'Amendments'
    click_link 'New', href: new_project_project_amendment_path(project)

    fill_in 'Requested at',            with: '15/06/2021'
    fill_in 'Amendment approved date', with: '15/06/2021'
    attach_file 'Upload', file_fixture('odr_amendment_request_form-1.0.pdf')
    check 'Data Flows'

    click_button 'Create Amendment'

    assert has_no_text?('This project cannot move to "DPIA" for 1 reason')
    assert has_no_text?('no amendment document attached')
    assert has_button?('Begin DPIA', disabled: false)
  end
end
