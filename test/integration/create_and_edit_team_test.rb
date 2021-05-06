require 'test_helper'

class CreateAndEditTeamTest < ActionDispatch::IntegrationTest
  def setup
    @admin        = users(:admin_user)
    @organisation = organisations(:test_organisation_one)

    login_and_accept_terms(@admin)
  end

  test 'can create a new team with noo members' do
    visit organisation_path(@organisation)

    click_link 'Add', href: new_organisation_team_path(@organisation)

    fill_in_team_data
    click_button 'Save'
    assert page.has_content?('Team was successfully created, please add team members ' \
                             'and set team to active')
    assert page.has_content?('Please activate team before creating projects')
    # we automaticaaly add the delegate user as a team member
    # Add the delegate grant from users
    assert_equal 0, Team.last.users.count
  end

  test 'can add multiple members to new team' do
    team     = teams(:team_NO_members)
    user_one = users(:standard_user)
    user_two = users(:standard_user2)
    role     = TeamRole.fetch(:mbis_applicant)

    visit team_path team
    # Add Team members
    within('#team_show_tabs') do
      click_on 'Users'
    end

    click_on 'Edit team grants'

    within('#user_search') do
      fill_in 'user_search[first_name]', with: 'standard'
      fill_in 'user_search[last_name]',  with: 'user'

      click_button 'Search'
    end

    check("grants_users_#{user_one.id}_#{role.id}")
    check("grants_users_#{user_two.id}_#{role.id}")

    click_button 'Update Roles'

    assert has_selector?('table#memberships-table tr', count: 2)
    assert_equal 2, team.users.count
  end

  test 'can create a new team with members' do
    user_one = users(:standard_user)
    user_two = users(:standard_user2)
    role     = TeamRole.fetch(:mbis_applicant)

    visit organisation_path(@organisation)

    click_link 'Add', href: new_organisation_team_path(@organisation)

    fill_in_team_data
    click_button 'Save'
    assert page.has_content?('Team was successfully created, please add team ' \
                             'members and set team to active')
    assert page.has_content?('Please activate team before creating projects')

    # Add Team members
    within('#team_show_tabs') do
      click_on 'Users'
    end
    click_on 'Edit team grants'

    within('#user_search') do
      fill_in 'user_search[first_name]', with: 'standard'
      fill_in 'user_search[last_name]',  with: 'user'

      click_button 'Search'
    end

    check("grants_users_#{user_one.id}_#{role.id}")
    check("grants_users_#{user_two.id}_#{role.id}")

    click_button('Update Roles')

    assert has_selector?('table#memberships-table tr', count: 2)

    team = Team.last
    assert team, 'No team was found!'
    assert_equal 2, team.users.count
  end

  test 'edit team' do
    team = teams(:team_two)
    visit team_path team
    click_link 'Edit'

    assert page.has_content?('Editing Team: team_two')
    fill_in 'team_notes', with: 'Change the notes about this team'
    click_button 'Save'

    within('#team-details-panel') do
      assert page.has_content?('Change the notes about this team')
    end
  end

  test 'can create team with addresses' do
    visit organisation_path(@organisation)
    click_link 'Add', href: new_organisation_team_path(@organisation)

    fill_in :team_name, with: 'Go Team'
    click_on 'Add Address'

    fill_in 'Add1', with: 'Address Line 1'
    fill_in 'Add2', with: 'Address Line 2'
    fill_in 'City', with: 'Sim'
    fill_in 'Telephone', with: '1234567'
    fill_in 'Postcode', with: 'AB1 2CD'
    assert_difference('Team.count') do
      assert_difference('Address.count') do
        click_button 'Save'
      end
    end
  end

  test 'users full name appears correctly on team edit screen' do
    team = teams(:team_two)
    visit team_path team
    within('#team_show_tabs') do
      click_on 'Users'
    end
    click_on 'Edit team grants'
    team.users.each do |user|
      assert has_content? user.full_name
    end
  end

  private

  def fill_in_team_data
    fill_in 'team_name', with: 'Test Team'
    select 'Directorate 1', from: 'team_directorate_id'
    select 'Division 1 from directorate 1', from: 'team_division_id'
    fill_in 'team_notes', with: 'Some interesting notes about this project'
  end
end
