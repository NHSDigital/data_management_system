require 'test_helper'

# test the workflow of an Application project
class ApplicationProjectTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:application_manager_one)
    @peer = users(:application_manager_two)
    @senior = users(:senior_application_manager_one)
    @odr = users(:odr_user)

    @project = projects(:test_application)

    sign_in @user
    visit terms_and_conditions_path
    click_on 'Accept'
  end

  test 'the DPIA process' do
    @project.transition_to!(workflow_states(:submitted))

    visit project_path(@project)
    assert has_no_button?('Begin DPIA')

    select @user.full_name, from: 'Application Manager'
    click_button 'Apply'
    accept_confirm { click_button 'Begin DPIA' }

    assert has_button?('Send for Peer Review', disabled: true)
    assert has_text?('This project cannot move to "DPIA Peer Review" for 1 reason')
    assert has_text?('no DPIA document(s) attached')

    create_dpia(@project)
    visit project_path(@project)

    reassign_for_moderation_to @peer

    click_button 'Reject DPIA'
    assert_emails 1 do
      within_modal(selector: '#modal-dpia_rejected') do
        select @user.full_name, from: 'project[assigned_user_id]'
        fill_in 'project_project_comments_attributes_0_comment', with: 'not today!'
        click_button 'Save'
      end
    end

    assert has_text? 'DPIA Rejected'
    assert has_no_button?('Begin DPIA')

    sign_in @user
    visit project_path(@project)
    assert has_button?('Begin DPIA')

    click_link 'Comment'
    assert has_text?('not today!')

    accept_confirm { click_button 'Begin DPIA' }

    reassign_for_moderation_to @peer

    click_button('Send for Moderation')
    assert_emails 1 do
      within_modal(selector: '#modal-dpia_moderation') do
        select @senior.full_name, from: 'project[assigned_user_id]'
        fill_in 'project_project_comments_attributes_0_comment', with: 'looks good'
        click_button 'Save'
      end
    end

    sign_in @senior
    visit project_path(@project)

    assert has_button? 'Reject DPIA'

    assert has_text?('This project cannot move to "Contract Draft" for 1 reason')
    assert has_text?('no contract document(s) attached')

    create_contract(@project)
    visit project_path(@project)

    accept_alert { click_button 'Start Contract Drafting' }

    # Challenge for it, then accept the response:
    ProjectsController.any_instance.expects(:valid_otp?).twice.returns(false).then.returns(true)

    within_modal(selector: '#yubikey-challenge') do
      fill_in 'ndr_authenticate[otp]', with: 'defo a yubikey'
      click_button 'Submit'
    end

    assert has_no_button? 'Start Contract Drafting'
    assert_equal workflow_states(:contract_draft), @project.reload.current_state

    sign_in @odr
    visit project_path(@project)

    assert has_no_content? 'no contract document(s) attached'
    assert has_button?  'Reject Contract'
    assert has_button?  'Mark Contract as Completed'

    accept_confirm { click_button 'Mark Contract as Completed' }

    # Challenge for it, then accept the response:
    ProjectsController.any_instance.expects(:valid_otp?).twice.
                       returns(false).then.returns(true)

    within_modal(selector: '#yubikey-challenge') do
      fill_in 'ndr_authenticate[otp]', with: 'defo a yubikey'
      click_button 'Submit'
    end

    assert has_text? 'Contract Completed'
  end

  test 'Article 6 and Article 9 should display seperately' do
    # Setup
    visit project_path(@project)
    click_on 'Edit'
    check 'Art. 6.1(a)'
    check 'Art. 6.1(f)'
    check 'Art. 9.2(b)'
    check 'Art. 9.2(d)'
    check 'Art. 9.2(i)'
    click_button 'Update Application'

    # Check Art. 6
    within('div.article6') do
      assert has_text? 'Article 6 lawful basis for processing personal data'
      assert has_text? 'Art. 6.1(a)'
      assert has_text? 'Art. 6.1(f)'
    end

    # Check Art. 9
    within('div.article9') do
      assert has_text? 'Article 9 condition for processing special category'
      assert has_text? 'Art. 9.2(b)'
      assert has_text? 'Art. 9.2(d)'
      assert has_text? 'Art. 9.2(i)'
    end
  end

  test 'Project Duration updates correctly' do
    visit project_path(@project)
    click_on 'Edit'
    assert page.has_text?('Unable to calculate duration')

    # Test Days
    fill_in 'project_start_data_date', with: '01/01/2018'
    fill_in('project_end_data_date', with: '10/01/2018').send_keys :tab
    assert page.has_text?('9 Days')

    # Test Months
    fill_in 'project_start_data_date', with: '01/01/2018'
    fill_in('project_end_data_date', with: '10/01/2019').send_keys :tab
    assert page.has_text?('12 Months')
  end

  test 'Project closure_date displays correctly' do
    closure_date = '01/01/2018'
    @project.update(closure_date: closure_date)
    visit project_path(@project)

    assert page.has_text?(closure_date)
  end

  test 'reset approvals should only show if user can reset approvals' do
    visit project_path(@project)
    assert has_no_content? 'Reset Approvals'

    @project.transition_to!(workflow_states(:submitted))
    visit project_path(@project)
    assert has_no_content? 'Reset Approvals'

    sign_in @odr
    visit project_path(@project)
    assert has_content? 'Reset Approvals'
  end

  test 'should not be able to edit users if the project is submitted' do
    visit project_path(@project)
    click_on 'Users'
    assert has_content? 'Edit'

    @project.transition_to!(workflow_states(:submitted))
    visit project_path(@project)
    click_on 'Users'
    assert has_no_content? 'Edit'
  end

  test 'should not be able to add or remove data items if the project is submitted' do
    visit project_path(@project)
    click_on 'Data Items'
    assert has_content? 'Add / Remove data items'

    @project.transition_to!(workflow_states(:submitted))
    visit project_path(@project)
    click_on 'Data Items'
    assert has_no_content? 'Add / Remove data items'
  end

  test 'should only approve legal / ethical when project is submitted' do
    project = projects(:new_project)

    visit project_path(project)
    click_on 'Legal / Ethical'
    assert has_content? 'Edit'
    assert has_no_content? 'Approve'

    project.transition_to!(workflow_states(:review))
    project.transition_to!(workflow_states(:submitted))

    sign_in @odr
    visit project_path(project)
    click_on 'Legal / Ethical'
    assert has_no_content? 'Edit'
    assert has_content? 'Approve'
  end

  test 'should show boolean dropdown options as Yes/No in show screen' do
    project = Project.create(project_type: project_types(:application), owner: @user,
                             name: 'Test yes/no', team: teams(:team_one),
                             onwardly_share: true, data_already_held_for_project: false)

    visit project_path(project)

    within('#onwardly_share') do
      assert has_content? 'Yes'
    end

    within('#data_already_held_for_project') do
      assert has_content? 'No'
    end

    within('#data_to_contact_others') do
      assert_not has_content? 'Yes'
      assert_not has_content? 'No'
    end
  end

  private

  def reassign_for_moderation_to(user)
    click_button 'Send for Peer Review'
    within_modal(selector: '#modal-dpia_review') do
      select user.full_name, from: 'project[assigned_user_id]'
      click_button 'Save'
    end

    assert has_no_button?('Send for Moderation')

    sign_in user
    visit project_path(@project)
    assert has_button?('Send for Moderation')
  end
end
