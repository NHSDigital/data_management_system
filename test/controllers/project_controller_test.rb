require 'test_helper'

class ProjectControllerTest < ActionDispatch::IntegrationTest
  def setup
    PaperTrail::Version.any_instance.stubs(whodunnit: users(:standard_user).id)
    @project = create_project
    @team = @project.team #teams(:team_one)
    User.any_instance.stubs(administrator?: true)
    @user = users(:standard_user2)
    sign_in(@user)
  end

  test 'should get index' do
    get team_url(@team)
    assert_response :success
  end

  # an admins could make a project before?
  test 'should get new' do
    get new_team_project_url(@team)
    assert_response :redirect
  end

  test 'should show team' do
    get project_url(@project)
    assert_response :success
  end

  test 'should get edit' do
    get edit_project_url(@project)
    assert_response :success
  end

  test 'should update project' do
    patch project_url(@project), params: { project: {
      name: 'New Project Name'
    } }
    assert_redirected_to project_url(@project)
  end

  test 'should destroy project' do
    assert_difference('Project.active.count', -1) do
      delete project_url(@project)
    end
    assert_redirected_to team_url(@team)
  end

  test 'should show dataset approvals' do
    @user = users(:cas_dataset_approver)
    sign_in(@user)

    get dataset_approvals_projects_url(@project)
    assert_response :success
  end
end
