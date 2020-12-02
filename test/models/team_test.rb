require 'test_helper'

class TeamTest < ActiveSupport::TestCase
  test 'should belong to an organisation' do
    team = teams(:team_one)

    assert_instance_of Organisation, team.organisation
  end

  test 'should be invalid without an organisation' do
    team = Team.new

    refute team.valid?
    assert_includes team.errors.details[:organisation], error: :blank
  end

  test 'should optionally belong to a division' do
    team = teams(:team_one)

    assert_instance_of Division, team.division

    team.division = nil
    team.valid?
    refute_includes team.errors.details[:division], error: :blank
  end

  test 'should optionally belong to a directorate' do
    team = teams(:team_one)

    assert_instance_of Directorate, team.directorate

    team.directorate = nil
    team.valid?
    refute_includes team.errors.details[:directorate], error: :blank
  end

  test 'blank team cannot be saved' do
    team = Team.new(organisation: organisations(:test_organisation_one))
    refute team.save
    team.name = 'Test team name'
    team.location = 'Big office, high street'
    team.directorate_id = 1
    team.division_id = 1
    team.delegate_approver = User.where(delegate_user: true).first.id
    team.z_team_status_id = 1
    assert team.save
  end

  test 'validate presence of name' do
    team = build_and_validate_team(name: '')
    refute team.valid?, 'should be invalid: no name'
    assert team.errors[:name].any?, 'name should have error when not present'
  end

  test 'validate presence of status' do
    team = build_and_validate_team(z_team_status_id: '')
    refute team.valid?, 'should be invalid: no status'
    assert team.errors[:z_team_status_id].any?, 'status should have error when not present'
  end

  test 'validate uniqueness of team names' do
    team = build_and_validate_team(name: 'Test name 999')
    assert team.save
    team2 = build_and_validate_team(name: 'Test name 999')
    refute team2.valid?, 'should be invalid: taken'
    assert team2.errors[:name].any?, 'has already been taken'
  end

  test 'active_users_who_are_not_team_members' do
    team = teams(:team_one)
    # this is the number of users who are not admin / odr or already part of the team
    assert_equal 27, team.active_users_who_are_not_team_members.count
    assert_equal 'Pick a Team member...', team.team_membership_prompt
    assert_equal false, team.disable_team_membership_dropdown?

    team.stubs(active_users_who_are_not_team_members: [])

    assert_equal 0, team.active_users_who_are_not_team_members.count
    assert_equal 'All active users are already Team members...', team.team_membership_prompt
    assert_equal true, team.disable_team_membership_dropdown?
  end

  test 'Can build polymorphic addresses for team' do
    team = teams(:team_one)
    team.addresses.build(add1: 'test1')
    team.addresses.build(add1: 'test2')
    assert team.valid?
    team.save && team.reload
    assert_equal 2, team.addresses.size
  end
end
