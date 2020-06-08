require 'test_helper'

class TeamsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @organisation = organisations(:test_organisation_one)
    @team         = teams(:team_MANY_members)

    sign_in(users(:admin_user))
  end

  test 'should get index' do
    get organisation_teams_url(@organisation)
    assert_response :success
  end

  test 'should get new' do
    get new_organisation_team_url(@organisation)
    assert_response :success
  end

  test 'should create team' do
    assert_difference('Team.count') do
      post organisation_teams_url(@organisation), params: { team: {
        location: @team.location, name: @team.name + 'new', notes: @team.notes,
        telephone: @team.telephone,
        z_team_status_id: @team.z_team_status_id,
        directorate_id: @team.directorate_id,
        division_id: @team.division_id,
        delegate_approver: @team.delegate_approver
      } }
    end

    assert_redirected_to team_path(Team.last)
  end

  test 'should show team' do
    get team_url(@team)
    assert_response :success
  end

  test 'should get edit' do
    get edit_team_url(@team)
    assert_response :success
  end

  test 'should update team' do
    patch team_url(@team), params: { team: {
      location: @team.location, name: @team.name, notes: @team.notes, postcode: @team.postcode,
      telephone: @team.telephone, z_team_status_id: @team.z_team_status_id
    } }
    assert_redirected_to team_path(@team)
  end

  # BP Need to check rules for deleting teams (should we just deactivate)
  # test "should destroy team" do
  #   assert_difference('Team.count', -1) do
  #     delete team_url(@team)
  #   end
  #
  #   assert_redirected_to teams_path
  # end
end
