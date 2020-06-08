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
end
