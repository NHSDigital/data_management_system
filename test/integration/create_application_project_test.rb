require 'test_helper'

class CreateApplicationProjectTest < ActionDispatch::IntegrationTest
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

  test_repeatedly 'create application', times: 20 do
    click_link 'Admin'
    click_link 'Teams'
    assert has_text? 'Listing Teams'
    click_link 'Details', match: :first
    assert has_text? 'team_one'
    click_button 'New'
    click_link 'Application'
    assert has_text? 'New ODR Application'
    select 'Standard User1', from: 'project_owner_grant_attributes_user_id'
    fill_in 'project_main_contact_name', with: 'Testing contact name'
    fill_in 'project_main_contact_email', with: 'Testing contact email'
    fill_in 'project_sponsor_name', with: 'Testing sponsor name'
    fill_in 'project_sponsor_add1', with: 'Testing sponsor add1'
    fill_in 'project_sponsor_add2', with: 'Testing sponsor add2'
    fill_in 'project_sponsor_city', with: 'Testing sponsor city'
    fill_in 'project_sponsor_postcode', with: 'Testing sponsor postcode'
    select 'UNITED KINGDOM', from: 'project_sponsor_country_id'
    fill_in 'project_funder_name', with: 'Testing funding name'
    fill_in 'project_funder_add1', with: 'Testing funder add1'
    fill_in 'project_funder_add2', with: 'Testing funder add2'
    fill_in 'project_funder_city', with: 'Testing funder city'
    fill_in 'project_funder_postcode', with: 'Testing funder postcode'
    select 'UNITED KINGDOM', from: 'project_funder_country_id'
    fill_in 'project_awarding_body_ref', with: 'Testing funder reference'
    fill_in 'project_name', with: 'New application test'
    select 'Test EOI', from: 'project_clone_of'
    fill_in 'project_description', with: 'Test project description'
    fill_in 'project_why_data_required', with: 'Testing why data required'
    fill_in 'project_how_data_will_be_used', with: 'Testing how data will be used'
    fill_in 'project_public_benefit', with: 'Testing public benefit'
    within('#project_end_uses') do
      check 'Research'
      check 'Service Evaluation'
    end
    fill_in 'project_end_use_other', with: 'Testing end use other'
    fill_in 'project_start_data_date', with: '01/01/2019'
    fill_in 'project_end_data_date', with: '01/01/2022'
    select 'Personally Identifiable', from: 'project_level_of_identifiability'
    fill_in 'project_data_linkage', with: 'Testing data linkage'
    select 'Yes', from: 'project_onwardly_share'
    fill_in 'project_onwardly_share_detail', with: 'Testing onwardly share detail'
    select 'Yes', from: 'project_data_already_held_for_project'
    fill_in 'project_data_already_held_detail', with: 'Testing data already held detail'
    select 'Yes', from: 'project_data_to_contact_others'
    fill_in 'project_data_to_contact_others_desc', with: 'Testing data to contact others desc'
    select 'Yes', from: 'project_programme_support_id'
    fill_in 'project_programme_support_detail', with: 'Testing programme support detail'
    fill_in 'project_scrn_id', with: 'Testing scrn id'
    fill_in 'project_programme_approval_date', with: '01/06/2019'
    fill_in 'project_phe_contacts', with: 'Testing phe contacts'
    fill_in 'project_acg_who', with: 'Testing acg who'
    select 'S251 Regulation 2', from: 'project_s251_exemption_id'
    fill_in 'project_cag_ref', with: 'Testing cag ref'
    fill_in 'project_date_of_renewal', with: '01/05/2019'
    check 'Art. 6.1(a)'
    check 'Art. 6.1(b)'
    check 'Art. 6.1(c)'
    check 'Art. 6.1(d)'
    check 'Art. 6.1(e)'
    check 'Art. 6.1(f)'
    check 'Art. 9.2(a)'
    check 'Art. 9.2(b)'
    check 'Art. 9.2(c)'
    check 'Art. 9.2(d)'
    check 'Art. 9.2(e)'
    check 'Art. 9.2(f)'
    check 'Art. 9.2(h)'
    check 'Art. 9.2(i)'
    check 'Art. 9.2(j)'
    fill_in 'project_ethics_approval_nrec_name', with: 'Testing ethics approval nrec name'
    fill_in 'project_ethics_approval_nrec_ref', with: 'Testing ethics approval nrec ref'
    select 'UK', from: 'project_processing_territory_id'
    fill_in 'project_processing_territory_other', with: 'Testing processing territory other'
    fill_in 'project_dpa_org_code', with: 'Testing dpa org code'
    fill_in 'project_dpa_org_name', with: 'Testing dpa org name'
    fill_in 'project_dpa_registration_end_date', with: '01/06/2022'
    select 'ISO 27001', from: 'project_security_assurance_id'
    fill_in 'project_ig_code', with: 'Testing ig code'
    fill_in 'project_data_processor_name', with: 'Testing data processor name'
    fill_in 'project_data_processor_add1', with: 'Testing data processor add1'
    fill_in 'project_data_processor_add2', with: 'Testing data processor add2'
    fill_in 'project_data_processor_city', with: 'Testing data processor city'
    fill_in 'project_data_processor_postcode', with: 'Testing data processor postcode'
    select 'UNITED KINGDOM', from: 'project_data_processor_country_id'
    select 'UK', from: 'project_processing_territory_outsourced_id'
    fill_in 'project_processing_territory_outsourced_other',
            with: 'Testing processing territory outsourced other'
    fill_in 'project_dpa_org_code_outsourced', with: 'Testing dpa org code outsourced'
    fill_in 'project_dpa_org_name_outsourced', with: 'Testing dpa org name outsourced'
    fill_in 'project_dpa_registration_end_date_outsourced', with: '01/04/2019'
    select 'ISO 27001', from: 'project_security_assurance_outsourced_id'
    fill_in 'project_ig_code_outsourced', with: 'Testing ig code outsourced'
    fill_in 'project_ig_toolkit_version_outsourced', with: 'Testing ig toolkit version outsourced'
    fill_in 'project_additional_info', with: 'Testing additional info'
    click_button 'Create Application'
    assert has_content?('Application was successfully created.')
    click_button 'Submit'

    project = Project.find_by(name: 'New application test')

    assert project.owner == User.find_by(username: 'standarduser1')
    assert project.main_contact_name == 'Testing contact name'
    assert project.main_contact_email == 'Testing contact email'
    assert project.sponsor_name == 'Testing sponsor name'
    assert project.sponsor_add1 == 'Testing sponsor add1'
    assert project.sponsor_add2 == 'Testing sponsor add2'
    assert project.sponsor_city == 'Testing sponsor city'
    assert project.sponsor_postcode == 'Testing sponsor postcode'
    assert project.sponsor_country_id == 'XKU'
    assert project.funder_name == 'Testing funding name'
    assert project.funder_add1 == 'Testing funder add1'
    assert project.funder_add2 == 'Testing funder add2'
    assert project.funder_city == 'Testing funder city'
    assert project.funder_postcode == 'Testing funder postcode'
    assert project.funder_country_id == 'XKU'
    assert project.awarding_body_ref == 'Testing funder reference'
    assert project.clone_of == Project.find_by(name: 'Test EOI').id
    assert project.description == 'Test project description'
    assert project.why_data_required == 'Testing why data required'
    assert project.how_data_will_be_used == 'Testing how data will be used'
    assert project.public_benefit == 'Testing public benefit'
    assert project.end_use_names.sort == ['Research', 'Service Evaluation'].sort
    assert project.end_use_other == 'Testing end use other'
    assert project.start_data_date == '01/01/2019'.to_date
    assert project.end_data_date == '01/01/2022'.to_date
    assert project.level_of_identifiability == 'Personally Identifiable'
    assert project.data_linkage == 'Testing data linkage'
    assert project.onwardly_share == true
    assert project.onwardly_share_detail == 'Testing onwardly share detail'
    assert project.data_already_held_for_project == true
    assert project.data_already_held_detail == 'Testing data already held detail'
    assert project.data_to_contact_others == true
    assert project.data_to_contact_others_desc == 'Testing data to contact others desc'
    assert project.programme_support_id == Lookups::ProgrammeSupport.find_by(value: 'Yes').id
    assert project.programme_support_detail == 'Testing programme support detail'
    assert project.scrn_id == 'Testing scrn id'
    assert project.programme_approval_date == '01/06/2019'.to_date
    assert project.phe_contacts == 'Testing phe contacts'
    assert project.acg_who == 'Testing acg who'
    assert project.s251_exemption_id ==
           Lookups::CommonLawExemption.find_by(value: 'S251 Regulation 2').id
    assert project.cag_ref == 'Testing cag ref'
    assert project.date_of_renewal == '01/05/2019'.to_date
    assert project.project_lawful_bases.map(&:lawful_basis_id).sort ==
           %w[6.1a 6.1b 6.1c 6.1d 6.1e 6.1f 9.2a 9.2b 9.2c 9.2d 9.2e 9.2f 9.2h 9.2i 9.2j].sort
    assert project.ethics_approval_nrec_name == 'Testing ethics approval nrec name'
    assert project.ethics_approval_nrec_ref == 'Testing ethics approval nrec ref'
    assert project.processing_territory_id == Lookups::ProcessingTerritory.find_by(value: 'UK').id
    assert project.processing_territory_other == 'Testing processing territory other'
    assert project.dpa_org_code == 'Testing dpa org code'
    assert project.dpa_org_name == 'Testing dpa org name'
    assert project.dpa_registration_end_date == '01/06/2022'.to_date
    assert project.security_assurance_id ==
           Lookups::SecurityAssurance.find_by(value: 'ISO 27001').id
    assert project.ig_code == 'Testing ig code'
    assert project.data_processor_name == 'Testing data processor name'
    assert project.data_processor_add1 == 'Testing data processor add1'
    assert project.data_processor_add2 == 'Testing data processor add2'
    assert project.data_processor_city == 'Testing data processor city'
    assert project.data_processor_postcode == 'Testing data processor postcode'
    assert project.data_processor_country_id == 'XKU'
    assert project.processing_territory_outsourced_id ==
           Lookups::ProcessingTerritory.find_by(value: 'UK').id
    assert project.processing_territory_outsourced_other ==
           'Testing processing territory outsourced other'
    assert project.dpa_org_code_outsourced == 'Testing dpa org code outsourced'
    assert project.dpa_org_name_outsourced == 'Testing dpa org name outsourced'
    assert project.dpa_registration_end_date_outsourced == '01/04/2019'.to_date
    assert project.security_assurance_outsourced_id ==
           Lookups::SecurityAssurance.find_by(value: 'ISO 27001').id
    assert project.ig_code_outsourced == 'Testing ig code outsourced'
    assert project.ig_toolkit_version_outsourced == 'Testing ig toolkit version outsourced'
    assert project.additional_info == 'Testing additional info'
  end

  test 'edit application' do
    visit project_path(@project)
    within('#project_status') do
      assert has_text?('New')
    end
    click_link 'Edit'
    assert has_text?('Edit Application: Test Application')
    fill_in 'project_description', with: 'making changes to an application'
    fill_in 'project_data_already_held_detail', with: 'Testing editing an application'
    check 'Art. 6.1(f)'
    check 'Art. 9.2(a)'
    fill_in 'project_funder_name', with: 'Testing funding name'
    fill_in 'project_funder_add1', with: 'Testing funder add1'
    fill_in 'project_funder_add2', with: 'Testing funder add2'
    fill_in 'project_funder_city', with: 'Testing funder city'
    fill_in 'project_funder_postcode', with: 'Testing funder postcode'
    select 'UNITED KINGDOM', from: 'project_funder_country_id'
    click_button 'commit'
    click_button 'Submit'

    project = Project.find_by(description: 'making changes to an application')

    assert project.data_already_held_detail == 'Testing editing an application'
    assert project.project_lawful_bases.map(&:lawful_basis_id).sort == %w[6.1f 9.2a].sort
    assert project.funder_name == 'Testing funding name'
    assert project.funder_add1 == 'Testing funder add1'
    assert project.funder_add2 == 'Testing funder add2'
    assert project.funder_city == 'Testing funder city'
    assert project.funder_postcode == 'Testing funder postcode'
    assert project.funder_country_id == 'XKU'
  end

  test 'Approve DPIA' do
    @project.transition_to!(workflow_states(:submitted))

    visit project_path(@project)
    assert has_no_button?('Begin DPIA')

    select @user.full_name, from: 'project_assignment'
    click_button 'Apply'
    assert has_button?('Begin DPIA')
    accept_alert { click_button 'Begin DPIA' }
    assert has_no_button?('Begin DPIA')

    assert has_button?('Send for Peer Review', disabled: true)
    assert has_text?('This project cannot move to "DPIA Peer Review" for 1 reason')
    assert has_text?('no DPIA document(s) attached')

    create_dpia(@project)
    visit project_path(@project)
    click_button 'Send for Peer Review'
    within_modal(selector: '#modal-dpia_review') do
      select @peer.full_name, from: 'project[assigned_user_id]'
      click_button 'Save'
    end
    within('#project_status') do
      assert has_text?('DPIA Peer Review')
    end
    assert_equal workflow_states(:dpia_review), @project.reload.current_state
  end

  test 'Reject DPIA' do
    @project.transition_to!(workflow_states(:submitted))

    visit project_path(@project)
    assert has_no_button?('Begin DPIA')

    select @user.full_name, from: 'project_assignment'
    click_button 'Apply'
    assert has_button?('Begin DPIA')
    accept_alert { click_button 'Begin DPIA' }
    assert has_no_button?('Begin DPIA')
    assert has_text?('This project cannot move to "DPIA Peer Review" for 1 reason:')
    click_button 'Close'
    within_modal(selector: '#modal-rejected') do
      fill_in 'project_comments_attributes_0_body', with: 'not today!'
      click_button 'Save'
    end
    select @peer.full_name, from: 'project_assignment'
    click_button 'Apply'
    within('#project_status') do
      assert has_text?('Closed')
    end
    assert_equal workflow_states(:rejected), @project.reload.current_state
  end

  test 'send for moderation' do
    @project.transition_to!(workflow_states(:submitted))
    visit project_path(@project)
    assert has_no_button?('Begin DPIA')
    select @user.full_name, from: 'project_assignment'
    click_button 'Apply'
    assert has_button?('Begin DPIA')
    accept_alert { click_button 'Begin DPIA' }
    assert has_no_button?('Begin DPIA')
    assert has_button?('Send for Peer Review', disabled: true)
    assert has_text?('This project cannot move to "DPIA Peer Review" for 1 reason')
    create_dpia(@project)
    visit project_path(@project)
    assert has_no_text?('This project cannot move to "DPIA Peer Review" for 1 reason')
    click_button 'Send for Peer Review'
    within_modal(selector: '#modal-dpia_review') do
      select @peer.full_name, from: 'project[assigned_user_id]'
      click_button 'Save'
    end
    sign_in @peer
    visit project_path(@project)
    within('#project_status') do
      assert has_text?('DPIA Peer Review')
    end
    assert_equal workflow_states(:dpia_review), @project.reload.current_state
    click_button 'Send for Moderation'
    within_modal(selector: '#modal-dpia_moderation') do
      select @senior.full_name, from: 'project[assigned_user_id]'
      fill_in 'project_comments_attributes_0_body', with: 'Ready for moderation'
      click_button 'Save'
    end

    within('#project_status') do
      assert has_text?('DPIA Moderation')
    end
    assert_equal workflow_states(:dpia_moderation), @project.reload.current_state
  end

  test 'Reject peer review' do
    @project.transition_to!(workflow_states(:submitted))
    visit project_path(@project)
    assert has_no_button? 'Begin DPIA'
    select @user.full_name, from: 'project[assigned_user_id]'
    click_button 'Apply'
    assert has_button?('Begin DPIA')
    accept_alert { click_button 'Begin DPIA' }
    assert has_no_button?('Begin DPIA')
    assert has_button?('Send for Peer Review', disabled: true)
    assert has_text?('This project cannot move to "DPIA Peer Review" for 1 reason')
    create_dpia(@project)
    visit project_path(@project)
    assert has_no_text?('This project cannot move to "DPIA Peer Review" for 1 reason')
    click_button 'Send for Peer Review'
    within_modal(selector: '#modal-dpia_review') do
      select @peer.full_name, from: 'project[assigned_user_id]'
      click_button 'Save'
    end
    sign_in @peer
    visit project_path(@project)
    within('#project_status') do
      assert has_text?('DPIA Peer Review')
    end
    assert_equal workflow_states(:dpia_review), @project.reload.current_state
    click_button 'Reject DPIA'
    within_modal(selector: '#modal-dpia_rejected') do
      select @user.full_name, from: 'project[assigned_user_id]'
      fill_in 'project_comments_attributes_0_body', with: 'Missing quite a lot'
      click_button 'Save'
    end
    within('#project_status') do
      assert has_text?('DPIA Rejected')
    end
    assert_equal workflow_states(:dpia_rejected), @project.reload.current_state
  end

  test 'Approve moderation' do
    @project.transition_to!(workflow_states(:submitted))
    visit project_path(@project)
    assert has_no_button?('Begin DPIA')
    select @user.full_name, from: 'project_assignment'
    click_button 'Apply'
    assert has_button?('Begin DPIA')
    accept_alert { click_button 'Begin DPIA' }
    assert has_no_button?('Begin DPIA')
    assert has_button?('Send for Peer Review', disabled: true)
    assert has_text?('This project cannot move to "DPIA Peer Review" for 1 reason')
    create_dpia(@project)
    visit project_path(@project)
    assert has_no_text?('This project cannot move to "DPIA Peer Review" for 1 reason')
    click_button 'Send for Peer Review'
    within_modal(selector: '#modal-dpia_review') do
      select @peer.full_name, from: 'project[assigned_user_id]'
      click_button 'Save'
    end
    sign_in @peer
    visit project_path(@project)
    within('#project_status') do
      assert has_text?('DPIA Peer Review')
    end
    assert_equal workflow_states(:dpia_review), @project.reload.current_state
    click_button 'Send for Moderation'
    within_modal(selector: '#modal-dpia_moderation') do
      select @senior.full_name, from: 'project[assigned_user_id]'
      fill_in 'project_comments_attributes_0_body', with: 'Ready for moderation'
      click_button 'Save'
    end
    within('#project_status') do
      assert has_text?('DPIA Moderation')
    end
    assert_equal workflow_states(:dpia_moderation), @project.reload.current_state
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
    within('#project_status') do
      assert has_text?('Contract Draft')
    end
    assert_equal workflow_states(:contract_draft), @project.reload.current_state
  end

  test 'reject moderation' do
    @project.transition_to!(workflow_states(:submitted))
    visit project_path(@project)
    assert has_no_button?('Begin DPIA')
    select @user.full_name, from: 'project_assignment'
    click_button 'Apply'
    assert has_button?('Begin DPIA')
    accept_alert { click_button 'Begin DPIA' }
    assert has_no_button?('Begin DPIA')
    assert has_button?('Send for Peer Review', disabled: true)
    assert has_text?('This project cannot move to "DPIA Peer Review" for 1 reason')
    create_dpia(@project)
    visit project_path(@project)
    assert has_no_text?('This project cannot move to "DPIA Peer Review" for 1 reason')
    click_button 'Send for Peer Review'
    within_modal(selector: '#modal-dpia_review') do
      select @peer.full_name, from: 'project[assigned_user_id]'
      click_button 'Save'
    end
    sign_in @peer
    visit project_path(@project)
    within('#project_status') do
      assert has_text?('DPIA Peer Review')
    end
    assert_equal workflow_states(:dpia_review), @project.reload.current_state
    click_button 'Send for Moderation'
    within_modal(selector: '#modal-dpia_moderation') do
      select @senior.full_name, from: 'project[assigned_user_id]'
      fill_in 'project_comments_attributes_0_body', with: 'Ready for moderation'
      click_button 'Save'
    end
    within('#project_status') do
      assert has_text?('DPIA Moderation')
    end
    assert_equal workflow_states(:dpia_moderation), @project.reload.current_state
    sign_in @senior
    visit project_path(@project)
    assert has_button? 'Reject DPIA'
    click_button 'Reject DPIA'
    within_modal(selector: '#modal-dpia_rejected') do
      select @user.full_name, from: 'project[assigned_user_id]'
      fill_in 'project_comments_attributes_0_body', with: 'Missing quite a lot'
      click_button 'Save'
    end
    within('#project_status') do
      assert has_text?('DPIA Rejected')
    end
    assert_equal workflow_states(:dpia_rejected), @project.reload.current_state
  end

  test 'contract complete' do
    @project.transition_to!(workflow_states(:submitted))
    visit project_path(@project)
    select @user.full_name, from: 'project_assignment'
    click_button 'Apply'
    assert has_button?('Begin DPIA')
    accept_alert { click_button 'Begin DPIA' }
    assert has_no_button?('Begin DPIA')
    create_dpia(@project)
    visit project_path(@project)
    click_button 'Send for Peer Review'
    within_modal(selector: '#modal-dpia_review') do
      select @peer.full_name, from: 'project[assigned_user_id]'
      click_button 'Save'
    end
    sign_in @peer
    visit project_path(@project)
    click_button 'Send for Moderation'
    within_modal(selector: '#modal-dpia_moderation') do
      select @senior.full_name, from: 'project[assigned_user_id]'
      fill_in 'project_comments_attributes_0_body', with: 'Ready for moderation'
      click_button 'Save'
    end
    sign_in @senior
    visit project_path(@project)
    create_contract(@project)
    visit project_path(@project)
    accept_alert { click_button 'Start Contract Drafting' }

    # Challenge for it, then accept the response:
    ProjectsController.any_instance.expects(:valid_otp?).twice.returns(false).then.returns(true)

    within_modal(selector: '#yubikey-challenge') do
      fill_in 'ndr_authenticate[otp]', with: 'defo a yubikey'
      click_button 'Submit'
    end
    sign_in @odr
    visit project_path(@project)
    assert has_button? 'Mark Contract as Completed'
    accept_alert { click_button 'Mark Contract as Completed' }

    # Challenge for it, then accept the response:
    ProjectsController.any_instance.expects(:valid_otp?).twice.returns(false).then.returns(true)

    within_modal(selector: '#yubikey-challenge') do
      fill_in 'ndr_authenticate[otp]', with: 'defo a yubikey'
      click_button 'Submit'
    end

    within('#project_status') do
      assert has_text?('Contract Completed')
    end
    assert_equal workflow_states(:contract_completed), @project.reload.current_state
  end

  test 'amendments' do
    @project.transition_to!(workflow_states(:submitted))
    visit project_path(@project)
    select @user.full_name, from: 'project_assignment'
    click_button 'Apply'
    assert has_button?('Begin DPIA')
    accept_alert { click_button 'Begin DPIA' }
    assert has_no_button?('Begin DPIA')
    assert has_button? 'Amend'
    accept_alert { click_button 'Amend' }
    assert has_no_button? 'Amend'
    click_link 'Amendments'
    click_link('new_amendment')
    fill_in 'project_amendment[requested_at]', with: '12/12/2019'
    attach_file('project_amendment[upload]', file_fixture('odr_amendment_request_form-1.0.pdf'))
    check 'Data Flows'
    check 'Data Items'
    check 'Data Source'
    check 'Processing Purpose'
    check 'Data Processor'
    check 'Duration'
    check 'Other'
    click_button 'Create Amendment'
    assert has_text? 'Amendment created successfully'
    assert has_button?('Begin DPIA')
    accept_alert { click_button 'Begin DPIA' }
    assert has_no_button?('Begin DPIA')
    create_dpia(@project)
    visit project_path(@project)
    assert has_no_text? 'This project cannot move to "DPIA Peer Review" for 1 reason'
    click_button 'Send for Peer Review'
    within_modal(selector: '#modal-dpia_review') do
      select @peer.full_name, from: 'project[assigned_user_id]'
      click_button 'Save'
    end
    sign_in @peer
    visit project_path(@project)
    assert has_button? 'Amend'
    accept_alert { click_button 'Amend' }
    assert has_no_button? 'Amend'
    click_link 'Amendments'
    assert has_button?('Begin DPIA')
    accept_alert { click_button 'Begin DPIA' }
    assert has_no_button?('Begin DPIA')
    click_button 'Send for Peer Review'
    within_modal(selector: '#modal-dpia_review') do
      select @user.full_name, from: 'project[assigned_user_id]'
      click_button 'Save'
    end
    sign_in @user
    visit project_path(@project)
    click_button 'Send for Moderation'
    within_modal(selector: '#modal-dpia_moderation') do
      select @senior.full_name, from: 'project[assigned_user_id]'
      fill_in 'project_comments_attributes_0_body', with: 'Ready for moderation'
      click_button 'Save'
    end
    within('#project_status') do
      assert has_text?('DPIA Moderation')
    end
    assert_equal workflow_states(:dpia_moderation), @project.reload.current_state
  end

  test 'contract rejected' do
    @project.transition_to!(workflow_states(:submitted))
    visit project_path(@project)
    select @user.full_name, from: 'project_assignment'
    click_button 'Apply'
    assert has_button?('Begin DPIA')
    accept_alert { click_button 'Begin DPIA' }
    assert has_no_button?('Begin DPIA')
    create_dpia(@project)
    visit project_path(@project)
    click_button 'Send for Peer Review'
    within_modal(selector: '#modal-dpia_review') do
      select @peer.full_name, from: 'project[assigned_user_id]'
      click_button 'Save'
    end
    sign_in @peer
    visit project_path(@project)
    click_button 'Send for Moderation'
    within_modal(selector: '#modal-dpia_moderation') do
      select @senior.full_name, from: 'project[assigned_user_id]'
      fill_in 'project_comments_attributes_0_body', with: 'Ready for moderation'
      click_button 'Save'
    end
    sign_in @senior
    visit project_path(@project)
    create_contract(@project)
    visit project_path(@project)
    accept_alert { click_button 'Start Contract Drafting' }

    # Challenge for it, then accept the response:
    ProjectsController.any_instance.expects(:valid_otp?).twice.returns(false).then.returns(true)

    within_modal(selector: '#yubikey-challenge') do
      fill_in 'ndr_authenticate[otp]', with: 'defo a yubikey'
      click_button 'Submit'
    end
    sign_in @odr
    visit project_path(@project)
    click_button 'Reject Contract'
    within_modal(selector: '#modal-contract_rejected') do
      select @user.full_name, from: 'project[assigned_user_id]'
      fill_in 'project_comments_attributes_0_body', with: 'Contract not ok'
      click_button 'Save'
    end
    sign_in @user
    visit project_path(@project)
    within('#project_status') do
      assert has_text?('Contract Rejected')
    end
    assert_equal workflow_states(:contract_rejected), @project.reload.current_state
  end

  test 'data released' do
    @project.transition_to!(workflow_states(:submitted))
    visit project_path(@project)
    select @user.full_name, from: 'project_assignment'
    click_button 'Apply'
    assert has_button?('Begin DPIA')
    accept_alert { click_button 'Begin DPIA' }
    assert has_no_button?('Begin DPIA')
    create_dpia(@project)
    visit project_path(@project)
    click_button 'Send for Peer Review'
    within_modal(selector: '#modal-dpia_review') do
      select @peer.full_name, from: 'project[assigned_user_id]'
      click_button 'Save'
    end
    sign_in @peer
    visit project_path(@project)
    click_button 'Send for Moderation'
    within_modal(selector: '#modal-dpia_moderation') do
      select @senior.full_name, from: 'project[assigned_user_id]'
      fill_in 'project_comments_attributes_0_body', with: 'Ready for moderation'
      click_button 'Save'
    end
    sign_in @senior
    visit project_path(@project)
    create_contract(@project)
    visit project_path(@project)
    accept_alert { click_button 'Start Contract Drafting' }

    # Challenge for it, then accept the response:
    ProjectsController.any_instance.expects(:valid_otp?).twice.returns(false).then.returns(true)

    within_modal(selector: '#yubikey-challenge') do
      fill_in 'ndr_authenticate[otp]', with: 'defo a yubikey'
      click_button 'Submit'
    end
    sign_in @odr
    visit project_path(@project)
    assert has_button? 'Mark Contract as Completed'
    accept_alert { click_button 'Mark Contract as Completed' }

    # Challenge for it, then accept the response:
    ProjectsController.any_instance.expects(:valid_otp?).twice.returns(false).then.returns(true)

    within_modal(selector: '#yubikey-challenge') do
      fill_in 'ndr_authenticate[otp]', with: 'defo a yubikey'
      click_button 'Submit'
    end

    within('#project_status') do
      assert has_text?('Contract Completed')
    end
    assert_equal workflow_states(:contract_completed), @project.reload.current_state
    select @user.full_name, from: 'project_assignment'
    click_button 'Apply'
    sign_in @user
    visit project_path(@project)
    assert has_button? 'Flag as Data Released'
    click_link 'Release'
    click_link 'New'
    fill_in 'release[invoice_requested_date]', with: '10/10/2019'
    fill_in 'release[invoice_sent_date]', with: '13/10/2019'
    fill_in 'release[phe_invoice_number]', with: '234592'
    fill_in 'release[po_number]', with: '122333'
    fill_in 'release[ndg_opt_out_processed_date]', with: '22/12/2020'
    fill_in 'release[cprd_reference]', with: 'test'
    fill_in 'release[actual_cost]', with: '3450'
    select 'Yes', from: 'release[vat_reg]'
    select 'Yes', from: 'release[income_received]'
    fill_in 'release[drr_no]', with: '234'
    select 'Yes', from: 'release[cost_recovery_applied]'
    fill_in 'release[individual_to_release]', with: 'Testing 123'
    fill_in 'release[release_date]', with: '22/11/2019'
    click_button 'Create Release'
    assert has_content? 'Release created successfully'
    sign_in @peer
    visit project_path(@project)
    within('#project_status') do
      assert has_text?('Data Released')
    end
    assert_equal workflow_states(:data_released), @project.reload.current_state
    sign_in @user
    visit project_path(@project)
    assert has_button?('Flag as Data Destroyed')
    accept_alert { click_button 'Flag as Data Destroyed' }
    assert has_no_button?('Flag as Data Destroyed')
    within('#project_status') do
      assert has_text?('Data Destroyed')
    end
    assert_equal workflow_states(:data_destroyed), @project.reload.current_state
  end
end
