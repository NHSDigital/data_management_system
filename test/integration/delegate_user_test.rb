require 'test_helper'

class DelegateUserTest < ActionDispatch::IntegrationTest
  test 'delegate_user can approve project' do
    Project.any_instance.stubs(new_project_submission_disabled: '')

    login_and_accept_terms(users(:delegate_user1))

    @project = projects(:pending_delegate_project)
    visit project_path(@project)

    accept_prompt do
      click_button 'Submit'
    end

    within '#project_status' do
      assert page.has_text? 'Pending'
    end

    @project.reload
    assert_equal @project.current_state.id, 'SUBMITTED'
  end

  test 'delegate_user can reject project' do
    login_and_accept_terms(users(:delegate_user1))

    @project = projects(:pending_delegate_project)
    visit project_path(@project)

    assert_difference -> { @project.comments.count } do
      click_button('Close')

      within_modal selector: '#modal-rejected' do
        fill_in 'project_comments_attributes_0_body', with: 'Delegate had rejected project details'
        click_button 'Save'
      end

      assert has_no_selector?('#modal-rejected', visible: true)
    end

    @project.reload
    assert_equal @project.current_state.id, 'REJECTED'
  end

  test 'delegate_user cannot edit project' do
    login_and_accept_terms(users(:delegate_user2))
    @project = projects(:new_delegate_project)
    visit project_path(@project)
    click_on 'Project Details'
    assert page.has_no_content?('Edit')
  end
end
