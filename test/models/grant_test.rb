require 'test_helper'

class GrantTest < ActiveSupport::TestCase
  test 'should only allow unique project grants' do
    project = projects(:one)

    build_project_grant(roleable: ProjectRole.fetch(:read_only)).tap(&:save)

    duplicate_grant = build_project_grant(roleable: ProjectRole.fetch(:read_only)).tap(&:save)
    refute duplicate_grant.valid?

    error_msg = 'Project already has this project grant!'

    assert duplicate_grant.errors[:project_id].any?
    assert_equal 1, duplicate_grant.errors.count
    assert duplicate_grant.errors.full_messages.include?(error_msg)

    duplicate_grant.user_id = users(:contributor).id

    assert duplicate_grant.valid?
  end

  test 'should only allow unique team grants' do
    team = teams(:team_one)

    build_team_grant(roleable: TeamRole.fetch(:read_only)).tap(&:save)

    duplicate_grant = build_team_grant(roleable: TeamRole.fetch(:read_only)).tap(&:save)
    refute duplicate_grant.valid?

    error_msg = 'Team already has this team grant!'

    assert duplicate_grant.errors[:team_id].any?
    assert_equal 1, duplicate_grant.errors.count
    assert duplicate_grant.errors.full_messages.include?(error_msg)

    duplicate_grant.user_id = users(:contributor).id

    assert duplicate_grant.valid?
  end

  test 'can destroy non owner project grant' do
    standard_grant = build_project_grant(user: users(:contributor),
                                         roleable: ProjectRole.fetch(:read_only))
    standard_grant.tap(&:save)
    standard_grant.reload
    assert standard_grant.destroy
  end

  # old membership tests

  test 'ensure user grants are destroyed via users' do
    new_user = create_user(email: 'grant_destroy_user@phe.gov.uk')
    new_user.grants << Grant.new(team: teams(:team_NO_members),
                                 roleable: TeamRole.fetch(:read_only))
    assert_difference('Grant.count', -1) do
      new_user.destroy
    end
  end

  test 'ensure user team grant is destroyed by team' do
    # teams(:team_MANY_members) has three members
    team = teams(:team_MANY_members)
    assert_difference('Grant.teams.count', -3) do
      team.destroy
    end
  end

  test 'should remove access to project when project grant is destroyed' do
    user = users(:standard_user2)
    assert_equal 1, user.projects.count
    assert_difference('Grant.count', -1) do
      user.projects.first.grants.find_by(user_id: user.id).destroy
    end

    assert_empty user.projects
  end

  test 'should add owner grant if project owner is set' do
    project = build_project(owner: nil)
    assert_nil project.owner
    assert_nil project.owner_grant
    project.owner = users(:standard_user2)
    assert project.owner_grant
    assert project.owner_grant.roleable
    assert project.valid?
  end

  test 'should only allow unique dataset grants' do
    build_dataset_grant(roleable: DatasetRole.fetch(:approver)).tap(&:save)

    duplicate_grant = build_dataset_grant(roleable: DatasetRole.fetch(:approver)).tap(&:save)
    refute duplicate_grant.valid?

    error_msg = 'Dataset already has this dataset grant!'

    assert duplicate_grant.errors[:dataset_id].any?
    assert_equal 1, duplicate_grant.errors.count
    assert duplicate_grant.errors.full_messages.include?(error_msg)

    duplicate_grant.user_id = users(:contributor).id

    assert duplicate_grant.valid?
  end

  test 'should return list of datasets for a user with dataset grants' do
    dataset = Dataset.find_by(name: 'COSD')

    build_dataset_grant(roleable: DatasetRole.fetch(:approver)).tap(&:save)
    cosd_grant = build_dataset_grant(roleable: DatasetRole.fetch(:approver), dataset: dataset).tap(&:save)

    assert_equal 2,users(:standard_user_one_team).datasets.count
    cosd_grant.destroy
    assert_equal 1,users(:standard_user_one_team).datasets.count
  end

  private

  def build_project_grant(options = {})
    default_options = {
      project: projects(:one),
      user: users(:standard_user_one_team)
    }
    Grant.new(default_options.merge(options))
  end

  def build_team_grant(options = {})
    default_options = {
      team: teams(:team_one),
      user: users(:standard_user_one_team)
    }
    Grant.new(default_options.merge(options))
  end

  def build_dataset_grant(options = {})
    default_options = {
      dataset: Dataset.find_by(name: 'SACT'),
      user: users(:standard_user_one_team)
    }
    Grant.new(default_options.merge(options))
  end
end
