require 'test_helper'

class VersionControllerTest < ActionDispatch::IntegrationTest
  test 'versions of team are created when created or updated' do
    team = create_team
    assert_equal 1, team.versions.count

    team.update(notes: 'These team notes have changed')
    assert_equal 2, team.versions.count
    expected_change = ['Test Team', 'These team notes have changed']
    assert_equal expected_change, team.versions.last.changeset['notes']
  end

  test 'versions of user are created when created or updated' do
    user = create_user
    assert_equal 1, user.versions.count

    user.update(notes: 'These User notes have changed')
    assert_equal 2, user.versions.count
    expected_change = ['This is a test user', 'These User notes have changed']
    assert_equal expected_change, user.versions.last.changeset['notes']
  end

  test 'versions of project are created when created or updated' do
    project = create_project
    # a second version is created when an association is added (team_data_source)
    assert_equal 1, project.versions.count

    project.update(name: 'NCRS - Updated Project Name')
    assert_equal 2, project.versions.count
    expected_change = ['NCRS', 'NCRS - Updated Project Name']
    assert_equal expected_change, project.versions.last.changeset['name']
  end
end
