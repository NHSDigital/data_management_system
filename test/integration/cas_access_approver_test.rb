require 'test_helper'

class CasAccessApproverTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:cas_access_approver)
  end

  test 'cas access approver should be able to update state to ACCESS_APPROVER_APPROVED' do
    sign_in @user

    project = Project.create(project_type: project_types(:cas), owner: users(:standard_user2))

    project.transition_to!(workflow_states(:submitted))

    visit project_path(project)

    # Auto-transitions through to ACCESS_GRANTED
    project_changes = { from: 'SUBMITTED', to: 'ACCESS_GRANTED' }
    assert_changes -> { project.reload.current_state.id }, project_changes do
      click_button('Approve Access')
      assert_difference('project.project_comments.count', 1) do
        within('.modal') do
          fill_in('Comment', with: 'Test')
          click_button('Save')
        end
        # Challenge for it, then accept the response:
        ProjectsController.any_instance.expects(:valid_otp?).twice.returns(false).then.returns(true)
        within_modal(selector: '#yubikey-challenge') do
          fill_in 'ndr_authenticate[otp]', with: 'defo a yubikey'
          click_button 'Submit'
        end
      end
    end
  end

  test 'cas access approver should be able to update state to ACCESS_APPROVER_REJECTED' do
    sign_in @user

    project = Project.create(project_type: project_types(:cas), owner: users(:standard_user2))

    project.transition_to!(workflow_states(:submitted))

    visit project_path(project)

    project_changes = { from: 'SUBMITTED', to: 'ACCESS_APPROVER_REJECTED' }
    assert_changes -> { project.reload.current_state.id }, project_changes do
      click_button('Reject Access')
      within('.modal') do
        fill_in('Comment', with: 'Test')
        click_button('Save')
      end
      within '#project_status' do
        assert page.has_text? 'Access Rejected'
      end
    end
  end
end
