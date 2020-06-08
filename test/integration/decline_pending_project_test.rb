require 'test_helper'

class DeclinePendingProjectTest < ActionDispatch::IntegrationTest
  def setup
    @project = create_project(
      team: teams(:team_one),
      senior_user_id: users(:standard_user2).id,
      project_type: project_types(:eoi),
      project_purpose: 'Test',
      state_ids: 'SUBMITTED',
      assigned_user: users(:application_manager_one)
    )
  end

  test 'application_manager can select closure_reason when declining a project' do
    login_and_accept_terms(users(:application_manager_one))
    visit project_path(@project)

    click_button('Decline')

    within '#modal-rejected' do
      select 'Duplicate', from: 'project[closure_reason_id]'
      click_button('Save')
    end

    within('#project_header') do
      assert page.has_content?('Declined')
    end

    within('#details') do
      assert page.has_content?('Duplicate')
    end
  end
end
