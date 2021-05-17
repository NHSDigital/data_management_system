require 'test_helper'

class AuditTest < ActionDispatch::IntegrationTest
  def setup
    @admin        = users(:admin_user)
    @organisation = organisations(:test_organisation_one)

    clear_headless_session!
    login_and_accept_terms(@admin)
  end

  test 'should not allow unauthorized access' do
    resource      = users(:admin_user)
    versions_path = papertrail_versions_path(resource_type: 'users', resource_id: resource)

    sign_out :user
    sign_in users(:standard_user)

    visit versions_path

    assert_equal root_path, current_path
  end

  test 'should allow authorized access' do
    resource      = users(:standard_user)
    versions_path = papertrail_versions_path(resource_type: 'users', resource_id: resource)

    sign_out :user
    sign_in users(:standard_user)

    visit versions_path

    assert_equal versions_path, current_path
  end

  test 'auditing of team' do
    user = users(:standard_user)
    role = TeamRole.fetch(:mbis_applicant)

    with_versioning do
      # Create a new team:
      visit organisation_path(@organisation)

      click_link 'Add', href: new_organisation_team_path(@organisation)

      fill_in_team_data
      click_button 'Save'

      # Check there's one version of the Team:
      page.find('#team-details-panel').click_link 'Audit'
      assert page.has_content? 'Team Audit'
      # First row is the header
      assert page.has_selector?('table#version-table tr', count: 2)
      page.find('#version-index-details').click_link 'Return to Team'

      # TODO: The delegate user should be there already:
      # page.assert_selector('#memberships-panel tbody tr', count: 1)
      # Add a team member
      within('#team_show_tabs') do
        click_on 'Users'
      end

      click_on 'Edit team grants'
      toggle_user_role(user, role)

      # The now the standard user should be there too:
      page.assert_selector('#memberships-panel tbody tr', count: 1)
      # Check that a Membership version has been created:
      page.find('#team-details-panel').click_link 'Audit'
      assert page.has_content?('Grant')
      # First row is the header
      assert page.has_selector?('table#version-table tr', count: 3)
      page.find('#version-table').click_link('Details', match: :first)
      within_modal do
        assert page.has_content?('Version 1 of 1')
        # 'sign_in_count' is one of the columns
        # that should not be displayed
        assert page.has_no_content?('sign_in_count')
        # Close the modal
        within '.modal-header' do
          click_button '×'
        end
      end
      page.find('#version-index-details').click_link 'Return to Team'

      # Edit Team details:
      page.find('#team-details-panel').click_link 'Edit'

      assert page.has_content?('Editing Team: Test Team')
      fill_in 'team_notes', with: 'Change the notes about this team'
      click_button 'Save'

      within('#team-details-panel') do
        assert page.has_content?('Change the notes about this team')
      end

      # Check that another version of Team has been created:
      page.find('#team-details-panel').click_link 'Audit'
      assert page.has_content?('update')
      # First row is the header
      assert page.has_selector?('table#version-table tr', count: 4)

      page.find('#version-table').click_link('Details', match: :first)
      within_modal(remain: true) do
        assert page.has_content?('Version 2 of 2')
        assert page.has_content?('Change the notes about this team')
        click_link 'Previous'
        assert page.has_content?('Version 1 of 2')
        assert page.has_content?('Some interesting notes about this project')
      end
    end
  end

  private

  def search_for_user(user)
    within('#user_search') do
      fill_in 'user_search[first_name]', with: user.first_name
      fill_in 'user_search[last_name]',  with: user.last_name
      fill_in 'user_search[email]',      with: user.email

      click_button 'Search'
    end
  end

  def toggle_user_role(user, role)
    search_for_user(user)

    within("tr#user_#{user.id}") do
      check("grants_users_#{user.id}_#{role.id}")
    end

    click_button('Update Roles')
  end
end
