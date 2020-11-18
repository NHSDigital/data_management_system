require 'test_helper'

class ApprovePendingProjectTest < ActionDispatch::IntegrationTest
  test 'odr_user can approve project' do
    login_and_accept_terms(users(:odr_user))
    @project = projects(:pending_project)
    visit project_path(@project)

    click_link('Details')
    find('#approve_details_status').find_link('Approve').click
    click_link('Data Items')
    assert page.has_content? 'Approve All'
    assert page.has_content? 'Undo All'
    page.find('#project_data_items_information').find('.glyphicon-ok').click
    assert find('#data_item_approval_status').has_text?('APPROVED')
    click_link('Users')
    find('#approve_members_status').find_link('Approve').click
    assert find('#user_approval_status').has_text?('APPROVED')
    click_link('Legal / Ethical')
    find('#approve_legal_status').find_link('Approve').click
    assert find('#legal_ethical_approval_status').has_text?('APPROVED')

    accept_prompt do
      click_button('Approve')
    end

    # Challenge for it, then accept the response:
    ProjectsController.any_instance.expects(:valid_otp?).twice.
                       returns(false).then.returns(true)

    within_modal(selector: '#yubikey-challenge') do
      fill_in 'ndr_authenticate[otp]', with: 'defo a yubikey'
      click_button 'Submit'
    end

    within '#project_status' do
      assert page.has_text? 'APPROVED'
    end

    # FIXME: Notifications are broken; need to be hooked i
    # assert_equal @project.members.count, Notification.last.user_notifications.count
  end

  test 'odr_user can decline project on project details' do
    project = projects(:pending_project)
    project.update(members_approved: true, legal_ethical_approved: true)
    project.project_nodes.update_all(approved: true)

    login_and_accept_terms(users(:odr_user))

    visit project_path(project)

    click_link('Details')

    find('#approve_details_status').find_link('Decline').click
    within_modal do
      fill_in 'project_comment_text_field', with: 'Rejected project details comment'
      click_button 'Save'
    end

    assert page.has_content?('Rejected project details comment')

    within('#project_header') do
      click_button 'Close'
    end

    within_modal selector: '#modal-rejected' do
      click_button 'Save'
    end

    within '#project_status' do
      assert page.has_text? 'Closed'
    end
  end

  test 'odr odr_user can decline project on member details' do
    project = projects(:pending_project)
    project.update(details_approved: true, legal_ethical_approved: true)
    project.project_nodes.update_all(approved: true)

    login_and_accept_terms(users(:odr_user))

    visit project_path(project)

    click_link('Users')

    find('#approve_members_status').find_link('Decline').click
    within_modal do
      fill_in 'project_comment_text_field', with: 'Rejected member details comment'
      click_button 'Save'
    end

    assert page.has_content?('Rejected member details comment')

    within '#project_header' do
      click_button 'Close'
    end

    within_modal selector: '#modal-rejected' do
      click_button 'Save'
    end

    within '#project_status' do
      assert page.has_text? 'Closed'
    end
  end

  test 'odr odr_user can decline project on legal details' do
    project = projects(:pending_project)
    project.update(details_approved: true, members_approved: true)
    project.project_nodes.update_all(approved: true)

    login_and_accept_terms(users(:odr_user))

    visit project_path(project)

    click_link('Legal / Ethical')

    find('#approve_legal_status').find_link('Decline').click
    within_modal do
      fill_in 'project_comment_text_field', with: 'Rejected legal details comment'
      click_button 'Save'
    end

    within '#project_header' do
      click_button 'Close'
    end

    within_modal selector: '#modal-rejected' do
      click_button 'Save'
    end

    within '#project_status' do
      assert page.has_text? 'Closed'
    end
  end

  # test 'odr_user can decline project on data source item details' do
  #   login_and_accept_terms(users(:odr_user))
  #   visit project_path(projects(:pending_project))
  #   find('#approve_details_status').find_link('Approve').click
  #   binding.pry
  #   find_all('.reject_data_source_item').first.click
  #   within_modal do
  #     fill_in 'project_comment_text_field',    with: 'Rejected data source item comment'
  #     click_button 'Save'
  #   end
  #   find('#approve_members_status').find_link('Decline').click
  #   assert_equal find('#all_approvals_answered').text, 'DECLINED'
  #   assert page.has_content?('Rejected data source item comment')
  # end
end
