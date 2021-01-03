require 'test_helper'

class CreateMbisProjectTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:senior_project_user)
    @team = teams(:team_two)
    @apman = users(:application_manager_one)
    login_and_accept_terms(@user)
  end

  test 'create project test' do
    visit team_path(@team)
    click_button 'New'
    click_link 'Project'
    click_button 'commit'
    assert has_content? "Project Title can't be blank"
    fill_in 'project_name', with: 'MBIS Test Project'
    click_button 'commit'
    assert has_no_content? "Project Title can't be blank"
    # end uses
    check 'Research'
    check 'Service Evaluation'
    fill_in 'project_end_use_other', with: 'Test'
    fill_in 'project_description', with: 'Test'
    select 'Yes', from: 'project_data_to_contact_others'
    fill_in 'project_data_to_contact_others_desc', with: 'Test'
    fill_in 'project_start_data_date', with: '11/12/2019'
    click_button 'commit'
    assert has_no_content? "Start data date can't be blank"
    fill_in 'project_end_data_date', with: (Date.current + 1.year).strftime('%d/%m/%Y)')
    click_button 'commit'
    assert has_no_content? "End data date can't be blank"
    select_and_accept_new_dataset('Births Gold Standard')
    select 'Yes', from: 'project_data_already_held_for_project'
    select 'Another User', from: 'project_owner_grant_attributes_user_id'
    fill_in 'project_cohort_inclusion_exclusion_criteria', with: 'Test'
    fill_in 'project_data_linkage', with: 'Test'
    select 'Annually', from: 'project_frequency'
    fill_in 'project_how_data_will_be_used', with: 'Test'
    # classifications
    select 'Anonymous', from: 'project_level_of_identifiability'
    select 'Yes', from: 'project_acg_support'
    fill_in 'project_acg_who', with: 'Test'
    fill_in 'project_acg_date', with: '06/12/2019'
    fill_in 'project_caldicott_email', with: 'Test@phe.gov.uk'
    select 'Yes', from: 'project_informed_patient_consent'
    select 'Yes', from: 'project_direct_care'
    select 'Yes', from: 'project_section_251_exempt'
    fill_in 'project_cag_ref', with: 'Test'
    fill_in 'project_date_of_approval', with: '06/12/2019'
    fill_in 'project_date_of_renewal', with: '06/12/2020'
    select 'Yes', from: 'project_regulation_health_services'
    select 'Yes', from: 'project_ethics_approval_obtained'
    fill_in 'project_ethics_approval_nrec_name', with: 'Test'
    fill_in 'project_ethics_approval_nrec_ref', with: 'Test'
    check 'project_output_ids_980190962'
    check 'project_output_ids_298486374'
    fill_in 'project_outputs_other', with: 'test'
    fill_in 'project_trackwise_id', with: 'test'
    assert_difference('Project.count', 1) do
      assert_difference('Grant.count', 1) do
        assert_difference('ProjectDataset.count', 1) do
          assert_difference('ProjectEndUse.count', 2) do
            click_button 'commit'
            assert has_no_content? 'Project datasets no datasets for project'
          end
        end
      end
    end
    assert has_no_content? 'Application Manager:'
    click_link 'Data Items'
    assert page.has_content?('Add / Remove data items')
    click_link 'Add / Remove data items'
    %w[FNAMM SNAMM DOB].each do |text|
      find('span', text: text, match: :first).click
    end

    assert_difference('ProjectNode.count', 3) do
      click_button 'commit', match: :first
    end

    assert_difference('ProjectComment.count', 3) do
      %w[FNAMM SNAMM DOB].each do |text|
        row = page.find('tr', text: text)
        assert_difference('ProjectComment.count', 1) do
          within row do
            find_link('Add Justification').evaluate_script('this.click()')
          end
          within_modal do
            fill_in 'project_comment_text_field', with: 'Test'
            click_button 'Save'
            assert has_no_content? 'Please fill in this field'
          end
        end
      end
    end
    click_link 'Legal / Ethical'
    click_link 'Users'
    click_link 'Edit'

    check("grants_users_#{users(:standard_user2).id}_#{ProjectRole.fetch(:contributor).id}")
    assert_difference('Grant.count', 1) do
      click_button 'Update Roles'
    end
    click_link 'Add End User'
    fill_in 'project_data_end_user_first_name', with: 'Test'
    fill_in 'project_data_end_user_last_name', with: 'Test'
    fill_in 'project_data_end_user_email', with: 'Test@Phe.gov.uk'
    select 'Yes', from: 'project_data_end_user_ts_cs_accepted'
    click_button 'Save'

    # TODO: Something flaky
    # assert_difference('ProjectDataEndUser.count', 1) do
    #   click_button 'Save'
    # end
    assert has_content? 'Test@Phe.gov.uk'
    project = Project.find_by(name: 'MBIS Test Project')
    assert_equal 1, project.project_data_end_users.count

    assert_difference('ProjectAttachment.count', 1) do
      click_link 'Uploads'
      click_link 'REC Approval Letter'
      click_link 'Upload'
      within_modal do
        assert has_text? 'Add an attachment'

        file = Rails.root.join('test', 'fixtures', 'files', 'REC Approval Letter.txt')
        attach_file('project_attachment_input_field', file)

        click_button 'Save'
      end

      assert page.has_content? 'REC Approval Letter successfully added to MBIS Test Project'
    end

    assert_difference('ProjectAttachment.count', -1) do
      click_link 'Uploads'
      click_link 'REC Approval Letter'
      click_link 'Delete'
      page.driver.browser.switch_to.alert.accept
      assert has_content? 'Attachment removed'
    end

    assert_difference('ProjectAttachment.count', 1) do
      click_link 'Uploads'
      click_link 'ONS Data Agreement Form'
      click_link 'Upload'
      within_modal do
        assert has_text? 'Add an attachment'

        file = Rails.root.join('test', 'fixtures', 'files', 'Other docs test.pdf')
        attach_file('project_attachment_input_field', file)

        click_button 'Save'
      end
      assert page.has_content? 'ONS Data Agreement Form successfully added to MBIS Test Project'
    end
    assert_difference('ProjectAttachment.count', -1) do
      click_link 'Uploads'
      click_link 'ONS Data Agreement Form'
      click_link 'Delete'
      page.driver.browser.switch_to.alert.accept
      assert has_content? 'Attachment removed'
    end
    assert_difference('ProjectAttachment.count', 1) do
      click_link 'Uploads'
      click_link 'Calidicott Approval Letter'
      click_link 'Upload'
      within_modal do
        assert has_text? 'Add an attachment'

        file = Rails.root.join('test', 'fixtures', 'files', 'Calidicott Approval letter test.pdf')
        attach_file('project_attachment_input_field', file)

        click_button 'Save'
      end
      assert page.has_content? 'Calidicott Approval Letter successfully added to MBIS Test Project'
    end
    assert_difference('ProjectAttachment.count', -1) do
      click_link 'Uploads'
      click_link 'Calidicott Approval Letter'
      click_link 'Delete'
      page.driver.browser.switch_to.alert.accept
      assert has_content? 'Attachment removed'
    end
    assert_difference('ProjectAttachment.count', 1) do
      click_link 'Uploads'
      click_link 'Section 251 Exemption'
      click_link 'Upload'
      within_modal do
        assert has_text? 'Add an attachment'

        file = Rails.root.join('test', 'fixtures', 'files', 'Section 251 Exemption.txt')
        attach_file('project_attachment_input_field', file)

        click_button 'Save'
      end
      assert page.has_content? 'Section 251 Exemption successfully added to MBIS Test Project'
    end
    assert_difference('ProjectAttachment.count', -1) do
      click_link 'Uploads'
      click_link 'Section 251 Exemption'
      click_link 'Delete'
      page.driver.browser.switch_to.alert.accept
      assert has_content? 'Attachment removed'
    end
    assert_difference('ProjectAttachment.count', 1) do
      click_link 'Uploads'
      click_link 'SLSP'
      click_link 'Upload'
      within_modal do
        assert has_text? 'Add an attachment'

        file = Rails.root.join('test', 'fixtures', 'files', 'SLSP test.pdf')
        attach_file('project_attachment_input_field', file)

        click_button 'Save'
      end
      assert page.has_content? 'SLSP successfully added to MBIS Test Project'
    end
    assert_difference('ProjectAttachment.count', -1) do
      click_link 'Uploads'
      click_link 'SLSP'
      click_link 'Delete'
      page.driver.browser.switch_to.alert.accept
      assert has_content? 'Attachment removed'
    end

    click_link 'Comments'
    assert has_content? 'Filter'
    within(id: 'tabs') do
      click_link 'Datasets'
    end
    assert has_content? 'Births Gold Standard'
    click_link 'Timeline'
    assert has_content? 'Status Updates'
    accept_prompt do
      click_button 'Submit for Delegate Approval'
    end
    assert has_no_content? 'Application Manager'
  end
end
