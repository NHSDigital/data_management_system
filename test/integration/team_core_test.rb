require 'test_helper'

class TeamCoreTest < ActionDispatch::IntegrationTest
  def setup
    @admin        = users(:admin_user)
    @organisation = organisations(:test_organisation_one)

    sign_in @admin
    visit terms_and_conditions_path
    click_on 'Accept'
    visit organisation_teams_path(@organisation)
  end

  test 'sign in and delete a team with no projects' do
    visit team_path(teams(:team_two))
    assert_difference('Team.active.count', -1) do
      accept_prompt do
        click_on 'delete_team_button'
      end

      assert page.has_content?('Team was successfully destroyed')
    end
  end

  test 'sign in and try to delete a team with projects' do
    visit team_path(teams(:team_one))
    assert_no_difference('Team.active.count') do
      accept_prompt do
        click_on 'delete_team_button'
      end

      assert page.has_content?('Team still has active projects so has not been deleted')
    end
  end

  test 'should be able to search for teams by name' do
    visit teams_path

    within('#search-form') do
      fill_in 'search[name]', with: 'team_one'
      click_button :submit, match: :first
    end

    assert_equal teams_path, current_path
    within('table') do
      assert has_text?('team_one')
      assert has_no_text?('team_two')
    end
  end

  test 'should be able to search for teams by organisation' do
    visit teams_path

    within('#search-form') do
      fill_in 'search[name]', with: 'Test Organisation Two'
      click_button :submit, match: :first
    end

    assert_equal teams_path, current_path
    within('table') do
      assert has_text?('Dream Team')
      assert has_no_text?('team_two')
    end
  end

  test 'should show teams organisation' do
    visit team_path(teams(:team_one))
    assert page.has_text?("Organisation: #{teams(:team_one).organisation.name}")
  end

  test 'should paginate team edit grants page' do
    team = teams(:team_one)

    visit edit_team_grants_path(team)

    assert has_selector?('tr.user', count: 20)
    assert has_selector?('.pagination')
  end

  test 'should be able to search by fullname and email in team edit grants page' do
    user = users(:standard_user1)

    visit edit_team_grants_path(teams(:team_one))

    within('#user_search') do
      fill_in 'user_search[first_name]', with: user.first_name
      fill_in 'user_search[last_name]',  with: user.last_name
      fill_in 'user_search[email]',      with: user.email

      click_button 'Search'
    end

    assert find('tr.user', count: 1)
    assert find('tr.user', text: 'Standard User1')
  end

  test 'should be able to search by fullname and email in project edit grants page' do
    visit edit_project_grants_path(projects(:test_application))

    # should show based on email search
    fill_in 'user_search', with: 'su11'

    assert find('tr', text: 'Standard User1', visible: true)
    assert find('tr', text: 'Standard2 User2', visible: false)

    # should show based on fullname search
    fill_in 'user_search', with: 'standard2'

    assert find('tr', text: 'Standard User1', visible: false)
    assert find('tr', text: 'Standard2 User2', visible: true)
  end
end
