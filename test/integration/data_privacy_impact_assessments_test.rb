require 'test_helper'

class DataPrivacyImpactAssessmentsTest < ActionDispatch::IntegrationTest
  def setup
    sign_in users(:application_manager_one)
  end

  test 'should be able to view the list of dpias' do
    project = projects(:test_application)
    dpia    = create_dpia(project)

    visit project_path(project)
    click_on('DPIAs')

    assert has_content?('DPIA attached')

    dom_id = "\#data_privacy_impact_assessment_#{dpia.id}"

    assert has_no_link?(href: new_project_data_privacy_impact_assessment_path(project))
    assert has_selector?(dom_id)

    within(dom_id) do
      within('#dpia_attached_date') do
        assert has_content?(Date.current.strftime('%d/%m/%Y').to_s)
      end
      assert has_link?(href: data_privacy_impact_assessment_path(dpia),         title: 'Details')
      assert has_no_link?(href: edit_data_privacy_impact_assessment_path(dpia), title: 'Edit')
      assert has_no_link?(href: data_privacy_impact_assessment_path(dpia),      title: 'Delete')
    end
  end

  test 'should be able to create a DPIA' do
    project = projects(:test_application)

    project.transition_to!(workflow_states(:submitted))
    project.transition_to!(workflow_states(:dpia_start))

    visit project_path(project)
    click_on('DPIAs')

    click_link('New')

    select project.reference,  from: 'Associated With'
    select 'Standards met',    from: 'data_privacy_impact_assessment[ig_assessment_status_id]'
    fill_in 'data_privacy_impact_assessment[ig_toolkit_version]',  with: '2019/20'
    fill_in 'data_privacy_impact_assessment[review_meeting_date]', with: '07/04/2020'
    fill_in 'data_privacy_impact_assessment[dpia_decision_date]',  with: '14/04/2020'
    attach_file('data_privacy_impact_assessment[upload]', file_fixture('dpia.txt'))

    assert_difference -> { project.global_dpias.count } do
      assert_difference -> { project.dpias.count } do
        click_button('Create DPIA')

        assert_equal project_path(project), current_path
        assert has_text?('DPIA created successfully')
        # assert has_selector?('#projectAmendments', visible: true)
      end
    end
  end

  test 'should be able to update a DPIA' do
    project = projects(:test_application)

    project.transition_to!(workflow_states(:submitted))
    project.transition_to!(workflow_states(:dpia_start))

    dpia = create_dpia(project)

    visit project_path(project)
    click_on('DPIAs')

    click_link(href: edit_data_privacy_impact_assessment_path(dpia))

    fill_in 'data_privacy_impact_assessment[dpia_decision_date]', with: '14/04/2020'

    assert_changes -> { dpia.reload.dpia_decision_date } do
      click_button('Update DPIA')

      assert_equal project_path(project), current_path
      assert has_text?('DPIA updated successfully')
      #assert has_selector?('#projectAmendments', visible: true)
    end
  end

  test 'should be able to destroy a DPIA' do
    project = projects(:test_application)

    project.transition_to!(workflow_states(:submitted))
    project.transition_to!(workflow_states(:dpia_start))

    dpia = create_dpia(project)

    visit project_path(project)
    click_on('DPIAs')

    assert_difference -> { project.global_dpias.count }, -1 do
      assert_difference -> { project.dpias.count }, -1 do
        accept_prompt do
          click_link(href: data_privacy_impact_assessment_path(dpia), title: 'Delete')
        end

        assert_equal project_path(project), current_path
      end
    end

    assert has_text?('DPIA destroyed successfully')
    # assert has_selector?('#projectAmendments', visible: true)
  end

  test 'should be able to view a DPIA' do
    project = projects(:test_application)
    dpia    = create_dpia(project)

    visit project_path(project)
    click_on('DPIAs')

    click_link(href: data_privacy_impact_assessment_path(dpia), title: 'Details')
    assert_equal data_privacy_impact_assessment_path(dpia), current_path
  end

  test 'should be able to download attached document' do
    project = projects(:test_application)
    dpia    = create_dpia(project)

    visit project_path(project)
    click_on('DPIAs')

    click_link(href: data_privacy_impact_assessment_path(dpia), title: 'Details')
    assert_equal data_privacy_impact_assessment_path(dpia), current_path

    accept_prompt do
      click_link(href: download_data_privacy_impact_assessment_path(dpia))
    end

    wait_for_download
    assert_equal 1, downloads.count
  end

  test 'should redirect if unauthorized' do
    sign_out users(:application_manager_one)
    sign_in  users(:standard_user)

    project = projects(:test_application)
    dpia    = create_dpia(project)

    visit edit_data_privacy_impact_assessment_path(dpia)

    refute_equal edit_data_privacy_impact_assessment_path(dpia), current_path
    assert has_text?('You are not authorized to access this page.')
  end
end
