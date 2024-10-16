require 'test_helper'

class CreateEoiProjectTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:senior_project_user)
    @team = teams(:team_two)
    @apman = users(:application_manager_one)
    login_and_accept_terms(@user)
  end

  flakey_test 'create eoi' do
    visit team_path(@team)
    click_button 'New'
    click_link 'EOI'

    assert has_field? 'project_first_contact_date'
    fill_in 'project_first_contact_date', with: '01/01/2021'

    select 'Another User', from: 'project_owner_grant_attributes_user_id'
    assert_text 'Project Title'
    fill_in 'project_name', with: 'Test EOI'
    fill_in 'project_project_purpose', with: 'Testing EOI'

    within('#multi_project_datasets') do
      element = find_new('select') { click_link('Add Dataset') }

      within(element) do
        select 'Births Gold Standard'
      end
    end

    # classifications
    assert_text 'Classification of data requested'
    select 'Anonymous', from: 'project_level_of_identifiability'
    # end uses
    assert_text 'Summary of project type'
    check 'Research'
    check 'Service Evaluation'

    assert_difference('Project.count', 1) do
      assert_difference('Grant.count', 1) do
        assert_difference('ProjectDataset.count', 1) do
          assert_difference('ProjectEndUse.count', 2) do
            click_button 'Create EOI'
            assert_text('EOI was successfully created')
          end
        end
      end
    end

    accept_prompt do
      click_button 'Submit'
    end
    click_on('another@phe.gov.uk')
    click_on('Logout')
    assert_text 'Signed out successfully.'
    login_and_accept_terms(@apman)
    click_on 'Projects'
    assert_text 'Assigned Projects'
    click_link 'Details', match: :first

    accept_prompt do
      click_button 'Approve'
    end
    assert_text('APPROVED')
  end
end
