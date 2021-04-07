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

  test 'create application' do
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

    accept_alert { click_button 'Submit' }

    project = Project.find_by(name: 'New application test')

    assert_equal User.find_by(username: 'standarduser1'), project.owner
    assert_equal 'Testing contact name', project.main_contact_name
    assert_equal 'Testing contact email', project.main_contact_email
    assert_equal 'Testing sponsor name', project.sponsor_name
    assert_equal 'Testing sponsor add1', project.sponsor_add1
    assert_equal 'Testing sponsor add2', project.sponsor_add2
    assert_equal 'Testing sponsor city', project.sponsor_city
    assert_equal 'Testing sponsor postcode', project.sponsor_postcode
    assert_equal 'XKU', project.sponsor_country_id
    assert_equal 'Testing funding name', project.funder_name
    assert_equal 'Testing funder add1', project.funder_add1
    assert_equal 'Testing funder add2', project.funder_add2
    assert_equal 'Testing funder city', project.funder_city
    assert_equal 'Testing funder postcode', project.funder_postcode
    assert_equal 'XKU', project.funder_country_id
    assert_equal 'Testing funder reference', project.awarding_body_ref
    assert_equal Project.find_by(name: 'Test EOI').id, project.clone_of
    assert_equal 'Test project description', project.description
    assert_equal 'Testing why data required', project.why_data_required
    assert_equal 'Testing how data will be used', project.how_data_will_be_used
    assert_equal 'Testing public benefit', project.public_benefit
    assert_equal ['Research', 'Service Evaluation'].sort, project.end_use_names.sort
    assert_equal 'Testing end use other', project.end_use_other
    assert_equal '01/01/2019'.to_date, project.start_data_date
    assert_equal '01/01/2022'.to_date, project.end_data_date
    assert_equal 'Personally Identifiable', project.level_of_identifiability
    assert_equal 'Testing data linkage', project.data_linkage
    assert_equal true, project.onwardly_share
    assert_equal 'Testing onwardly share detail', project.onwardly_share_detail
    assert_equal true, project.data_already_held_for_project
    assert_equal 'Testing data already held detail', project.data_already_held_detail
    assert_equal true, project.data_to_contact_others
    assert_equal 'Testing data to contact others desc', project.data_to_contact_others_desc
    assert_equal Lookups::ProgrammeSupport.find_by(value: 'Yes').id, project.programme_support_id
    assert_equal 'Testing programme support detail', project.programme_support_detail
    assert_equal 'Testing scrn id', project.scrn_id
    assert_equal '01/06/2019'.to_date, project.programme_approval_date
    assert_equal 'Testing phe contacts', project.phe_contacts
    assert_equal 'Testing acg who', project.acg_who
    assert_equal Lookups::CommonLawExemption.find_by(value: 'S251 Regulation 2').id,
                 project.s251_exemption_id
    assert_equal 'Testing cag ref', project.cag_ref
    assert_equal '01/05/2019'.to_date, project.date_of_renewal
    assert_equal %w[6.1a 6.1b 6.1c 6.1d 6.1e 6.1f 9.2a 9.2b 9.2c 9.2d 9.2e 9.2f 9.2h 9.2i 9.2j].sort,
                 project.project_lawful_bases.map(&:lawful_basis_id).sort
    assert_equal 'Testing ethics approval nrec name', project.ethics_approval_nrec_name
    assert_equal 'Testing ethics approval nrec ref', project.ethics_approval_nrec_ref
    assert_equal Lookups::ProcessingTerritory.find_by(value: 'UK').id, project.processing_territory_id
    assert_equal 'Testing processing territory other', project.processing_territory_other
    assert_equal 'Testing dpa org code', project.dpa_org_code
    assert_equal 'Testing dpa org name', project.dpa_org_name
    assert_equal '01/06/2022'.to_date, project.dpa_registration_end_date
    assert_equal Lookups::SecurityAssurance.find_by(value: 'ISO 27001').id,
                 project.security_assurance_id
    assert_equal 'Testing ig code', project.ig_code
    assert_equal 'Testing data processor name', project.data_processor_name
    assert_equal 'Testing data processor add1', project.data_processor_add1
    assert_equal 'Testing data processor add2', project.data_processor_add2
    assert_equal 'Testing data processor city', project.data_processor_city
    assert_equal 'Testing data processor postcode', project.data_processor_postcode
    assert_equal 'XKU', project.data_processor_country_id
    assert_equal Lookups::ProcessingTerritory.find_by(value: 'UK').id,
                 project.processing_territory_outsourced_id
    assert_equal 'Testing processing territory outsourced other',
                 project.processing_territory_outsourced_other
    assert_equal 'Testing dpa org code outsourced', project.dpa_org_code_outsourced
    assert_equal 'Testing dpa org name outsourced', project.dpa_org_name_outsourced
    assert_equal '01/04/2019'.to_date, project.dpa_registration_end_date_outsourced
    assert_equal Lookups::SecurityAssurance.find_by(value: 'ISO 27001').id,
                 project.security_assurance_outsourced_id
    assert_equal 'Testing ig code outsourced', project.ig_code_outsourced
    assert_equal 'Testing ig toolkit version outsourced', project.ig_toolkit_version_outsourced
    assert_equal 'Testing additional info', project.additional_info
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

    accept_alert { click_button 'Submit' }

    project = Project.find_by(description: 'making changes to an application')

    assert_equal 'Testing editing an application', project.data_already_held_detail
    assert_equal %w[6.1f 9.2a].sort, project.project_lawful_bases.map(&:lawful_basis_id).sort
    assert_equal 'Testing funding name', project.funder_name
    assert_equal 'Testing funder add1', project.funder_add1
    assert_equal 'Testing funder add2', project.funder_add2
    assert_equal 'Testing funder city', project.funder_city
    assert_equal 'Testing funder postcode', project.funder_postcode
    assert_equal 'XKU', project.funder_country_id
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
    assert_equal @project.reload.current_state, workflow_states(:dpia_review)
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
    assert_equal @project.reload.current_state, workflow_states(:rejected)
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
    assert_equal @project.reload.current_state, workflow_states(:dpia_review)
    click_button 'Send for Moderation'
    within_modal(selector: '#modal-dpia_moderation') do
      select @senior.full_name, from: 'project[assigned_user_id]'
      fill_in 'project_comments_attributes_0_body', with: 'Ready for moderation'
      click_button 'Save'
    end

    within('#project_status') do
      assert has_text?('DPIA Moderation')
    end
    assert_equal @project.reload.current_state, workflow_states(:dpia_moderation)
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
    assert_equal @project.reload.current_state, workflow_states(:dpia_review)
    click_button 'Reject DPIA'
    within_modal(selector: '#modal-dpia_rejected') do
      select @user.full_name, from: 'project[assigned_user_id]'
      fill_in 'project_comments_attributes_0_body', with: 'Missing quite a lot'
      click_button 'Save'
    end
    within('#project_status') do
      assert has_text?('DPIA Rejected')
    end
    assert_equal @project.reload.current_state, workflow_states(:dpia_rejected)
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
    assert_equal @project.reload.current_state, workflow_states(:dpia_review)
    click_button 'Send for Moderation'
    within_modal(selector: '#modal-dpia_moderation') do
      select @senior.full_name, from: 'project[assigned_user_id]'
      fill_in 'project_comments_attributes_0_body', with: 'Ready for moderation'
      click_button 'Save'
    end
    within('#project_status') do
      assert has_text?('DPIA Moderation')
    end
    assert_equal @project.reload.current_state, workflow_states(:dpia_moderation)
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
    assert_equal @project.reload.current_state, workflow_states(:contract_draft)
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
    assert_equal @project.reload.current_state, workflow_states(:dpia_review)
    click_button 'Send for Moderation'
    within_modal(selector: '#modal-dpia_moderation') do
      select @senior.full_name, from: 'project[assigned_user_id]'
      fill_in 'project_comments_attributes_0_body', with: 'Ready for moderation'
      click_button 'Save'
    end
    within('#project_status') do
      assert has_text?('DPIA Moderation')
    end
    assert_equal @project.reload.current_state, workflow_states(:dpia_moderation)
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
    assert_equal @project.reload.current_state, workflow_states(:dpia_rejected)
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
    assert_equal @project.reload.current_state, workflow_states(:contract_completed)
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
    assert_equal @project.reload.current_state, workflow_states(:dpia_moderation)
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
    assert_equal @project.reload.current_state, workflow_states(:contract_rejected)
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
    assert_equal @project.reload.current_state, workflow_states(:contract_completed)
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
    assert_equal @project.reload.current_state, workflow_states(:data_released)
    sign_in @user
    visit project_path(@project)
    assert has_button?('Flag as Data Destroyed')
    accept_alert { click_button 'Flag as Data Destroyed' }
    assert has_no_button?('Flag as Data Destroyed')
    within('#project_status') do
      assert has_text?('Data Destroyed')
    end
    assert_equal @project.reload.current_state, workflow_states(:data_destroyed)
  end
end
