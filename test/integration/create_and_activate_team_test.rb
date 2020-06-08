require 'test_helper'

class CreateAndActivateTeamTest < ActionDispatch::IntegrationTest
  def setup
    @admin        = users(:admin_user)
    @organisation = organisations(:test_organisation_one)

    login_and_accept_terms(@admin)
  end

  test 'can create a new team with no members cannot activate team' do
    visit organisation_path(@organisation)

    click_link 'Add', href: new_organisation_team_path(@organisation)

    fill_in_team_data('Test Team 1')
    click_button 'Save'
    assert page.has_content?('Please activate team before creating projects')
    # TODO: Delegate not added at Team level in new grants world
    assert_equal 0, Team.last.users.count
    assert page.find_link('ACTIVATE').matches_css?('.disabled')
  end

  # Complex Team is a team that with multiple datasets and members
  test 'can create and activate a new complex team (member added last)' do
    visit organisation_path(@organisation)

    click_link 'Add', href: new_organisation_team_path(@organisation)

    fill_in_team_data('Test Team 2')
    click_button 'Save'
    assert page.has_content?('Please activate team before creating projects')
    # TODO: Delegate not added at Team level in new grants world
    assert_equal 0, Team.last.users.count
    assert page.find_link('ACTIVATE').matches_css?('.disabled')

    # Add a Team member
    # TODO: need to be applicant role once team grants edit page is updated
    within('#team_show_tabs') do
      click_on 'Users'
    end
    click_on 'Edit team grants'
    page.check("grants_users_#{users(:standard_user).id}_#{TeamRole.fetch(:mbis_applicant).id}")
    find_button('Update Roles').click

    assert page.find_link('ACTIVATE')
    assert page.find_link('ACTIVATE').not_matches_css?('.disabled')
    assert page.find_link('ACTIVATE').matches_css?('.btn-success')

    team = Team.last
    assert_equal 1, team.users.count
  end

  # Complex Team is a team that with multiple datasets and members
  test 'can create and activate a new complex team (member added first)' do
    visit organisation_path(@organisation)

    click_link 'Add', href: new_organisation_team_path(@organisation)

    fill_in_team_data('Test Team 3')
    click_button 'Save'
    assert page.has_content?('Please activate team before creating projects')
    # TODO: Delegate not added at Team level in new grants world
    assert_equal 0, Team.last.users.count
    assert page.find_link('ACTIVATE').matches_css?('.disabled')

    # Add a Team member
    # TODO: need to be applicant role once team grants edit page is updated
    within('#team_show_tabs') do
      click_on 'Users'
    end
    click_on 'Edit team grants'
    page.check("grants_users_#{users(:standard_user).id}_#{TeamRole.fetch(:mbis_applicant).id}")
    find_button('Update Roles').click
    assert page.find_link('ACTIVATE').not_matches_css?('.disabled')
    assert page.find_link('ACTIVATE').matches_css?('.btn-success')

    team = Team.last
    assert_equal 1, team.users.count
  end

  test 'can activate a team, when datasets and members added' do
    visit organisation_path(@organisation)

    click_link 'Add', href: new_organisation_team_path(@organisation)

    fill_in_team_data('Test Team 4')
    click_button 'Save'

    # Add a Team member
    # TODO: need to be applicant role once team grants edit page is updated
    within('#team_show_tabs') do
      click_on 'Users'
    end
    click_on 'Edit team grants'
    page.check("grants_users_#{users(:standard_user).id}_#{TeamRole.fetch(:mbis_applicant).id}")
    find_button('Update Roles').click
    assert page.find_link('ACTIVATE').matches_css?('.btn-success')
    click_link 'ACTIVATE'
    assert_equal Notification.last.title, 'New team created in MBIS : Test Team 4'
    assert Notification.last.admin_users

    assert has_no_selector?('#modal', visible: true)

    # Add a Team member
    # TODO: need to be applicant role once team grants edit page is updated
    within('#team_show_tabs') do
      click_on 'Users'
    end
    click_on 'Edit team grants'
    page.check("grants_users_#{users(:standard_user2).id}_#{TeamRole.fetch(:mbis_applicant).id}")
    find_button('Update Roles').click

    assert has_no_selector?('#modal', visible: true)
    assert_equal 'New team created in MBIS : Test Team 4', Notification.last.title 
    # TODO: do we really want to email every time we edit a grant?
    # assert Notification.last.body.include? 'Team member Standard2 User2 added to team Test Team'
    assert Notification.last.admin_users
  end

  private

  def fill_in_team_data(team_name)
    fill_in 'team_name',         with: team_name
    select 'Directorate 1', from: 'team_directorate_id'
    select 'Division 1 from directorate 1', from: 'team_division_id'
    # check 'Delegate1 User'
    fill_in 'team_notes',        with: 'Some interesting notes about this project'
  end
end
