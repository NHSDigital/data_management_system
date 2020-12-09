require 'test_helper'

class CasAccessApproverTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:cas_access_approver)
  end

  test 'should be able to view list of projects that user has access to approve' do
    sign_in @user

    project = Project.create(project_type: project_types(:cas), owner: users(:standard_user2))

    project.transition_to!(workflow_states(:awaiting_account_approval))

    visit project_path(project)

    project_changes = { from: 'AWAITING_ACCOUNT_APPROVAL', to: 'APPROVED' }

    assert_changes -> { project.reload.current_state.id }, project_changes do
      accept_confirm do
        click_button('Approve')
      end
      within '#project_status' do
        assert page.has_text? 'APPROVED'
      end
    end

    project_changes = { from: 'APPROVED', to: 'REJECTED' }

    assert_changes -> { project.reload.current_state.id }, project_changes do
      click_button('Close')
      within('.modal') do
        fill_in('Comment', with: 'Test')
        click_button('Save')
      end
      within '#project_status' do
        assert page.has_text? 'Closed'
      end
    end

    project_changes = { from: 'REJECTED', to: 'DRAFT' }

    assert_changes -> { project.reload.current_state.id }, project_changes do
      accept_confirm do
        click_button('Return to draft')
      end
      within '#project_status' do
        assert page.has_text? 'New'
      end
    end
  end
end
