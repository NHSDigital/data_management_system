require 'test_helper'
# test the workflow of an EOI project
class EoiProjectTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:application_manager_one)
    @project = projects(:test_eoi)
    @project.owner = @user
    @project.save!

    sign_in @user
    visit terms_and_conditions_path
    click_on 'Accept'
  end

  test 'approve EOI' do
    @project.transition_to!(workflow_states(:submitted))
    visit project_path(@project)

    select @user.full_name, from: 'project_assignment'
    click_button 'Apply'

    assert has_text?('EOI was successfully assigned')
    accept_alert { click_button 'Approve' }

    within('#project_status') do
      assert has_text?('APPROVED')
    end
    assert_equal workflow_states(:approved), @project.reload.current_state
  end

  test 'reject EOI' do
    @project.transition_to!(workflow_states(:submitted))
    visit project_path(@project)

    select @user.full_name, from: 'project_assignment'
    click_button 'Apply'
    assert has_text?('EOI was successfully assigned')

    click_button 'Close'
    within_modal(selector: '#modal-rejected') do
      fill_in 'project_comments_attributes_0_body', with: 'Testing project comments'
      click_button 'Save'
    end
    within('#project_status') do
      assert has_text?('Closed')
    end
    assert_equal workflow_states(:rejected), @project.reload.current_state
  end

  test 'edit EOI' do
    visit project_path(@project)
    click_link 'Edit'

    fill_in 'project[name]', with: 'Testing edit EOI'
    fill_in 'project_project_purpose', with: 'Changed description'
    select 'De-personalised', from: 'project_level_of_identifiability'
    check 'Research'
    check 'Service Evaluation'
    click_button 'commit'

    assert has_text?('EOI was successfully updated.')
    accept_alert { click_button 'Submit' }

    within('#project_status') do
      assert has_text?('Pending')
    end
    assert_equal workflow_states(:submitted), @project.reload.current_state

    assert_equal 'Testing edit EOI', @project.name
    assert_equal 'Changed description', @project.project_purpose
    assert_equal 'De-personalised', @project.level_of_identifiability
    assert_equal ['Research', 'Service Evaluation'].sort, @project.end_use_names.sort
  end
end
