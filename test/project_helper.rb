module ActionDispatch
  class IntegrationTest
    def edit_links_or_buttons_not_available
      within('#project_header_information') do
        assert page.has_no_link?('Submit for Approval')
      end
      click_link('Project Details')
      within('#approve_details_status') do
        assert page.has_no_content?('Edit')
      end
      click_link('Users')
      assert page.has_no_content?('Add Member')
      assert page.has_no_content?('Add End User')
      click_link('Legal / Ethical')
      within('#approve_legal_status') do
        assert page.has_no_content?('Edit')
      end
      assert page.has_no_content?('Add / Remove data items')
      assert page.has_no_content?('Edit')
    end

    def edit_links_or_buttons_available
      within('#project_header_information') do
        assert page.has_link?('Team')
        assert page.has_link?('Submit for Delegate Approval')
      end
      click_link('Project Details')
      within('#approve_details_status') do
        assert page.has_content?('Edit')
      end
      click_link('Users')
      assert page.has_content?('Add Member')
      assert page.has_content?('Add End User')
      click_link('Legal / Ethical')
      within('#approve_legal_status') do
        assert page.has_content?('Edit')
      end
      click_link('Data Items')
      assert page.has_content?('Add / Remove data items')
    end

    def approval_links_or_buttons_available
      assert page.has_link?('reset_approvals_button')
      assert page.has_link?('save_approvals_button')
      assert page.has_link?('save_and_submit_approvals_button')
      click_link('Project Details')
      within('#approve_details_status') do
        assert page.has_content?('Approve')
        assert page.has_content?('Decline')
      end
      click_link('Users')
      within('#approve_members_status') do
        assert page.has_content?('Approve')
        assert page.has_content?('Decline')
      end
      click_link('Legal / Ethical')
      within('#approve_legal_status') do
        assert page.has_content?('Approve')
        assert page.has_content?('Decline')
      end
    end

    def approval_links_or_buttons_not_available
      # no reset-approvals / save / save and submit
      assert page.has_no_link?('#reset_approvals_button')
      assert page.has_no_link?('#save_approvals_button')
      assert page.has_no_link?('#save_and_submit_approvals_button')
      click_link('Project Details')
      within('#approve_details_status') do
        assert page.has_no_content?('Approve')
        assert page.has_no_content?('Decline')
      end
      click_link('Users')
      within('#approve_members_status') do
        assert page.has_no_content?('Approve')
        assert page.has_no_content?('Decline')
      end
      click_link('Legal / Ethical')
      within('#approve_legal_status') do
        assert page.has_no_content?('Approve')
        assert page.has_no_content?('Decline')
      end
    end

    def overall_status_messages(message)
      assert_equal find('#all_approvals_answered').text, message
    end

    def status_messages(message)
      assert_equal find('#all_approvals_answered').text, message
      assert find('#data_item_approval_status').text has_content?(message)
      assert find('#user_approval_status').text has_content?(message)
      assert find('#legal_ethical_approval_status').text has_content?(message)
    end
  end
end
