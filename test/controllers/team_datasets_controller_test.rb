require 'test_helper'
# TODO: replaced by project_datasets
class TeamDatasetsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:standard_user_one_team)
    @admin = users(:admin_user)
  end
=begin
  test 'should not get new team data source unless current user is admin' do
    refute @user.administrator?
    sign_in(@user)
    get new_team_team_data_source_url teams(:team_one)
    assert_redirected_to root_url
  end

  test 'should new team data source when current user is admin' do
    sign_in(@admin)
    get new_team_team_data_source_url teams(:team_one)
    assert_response :success
  end

  test 'index should redirect to team' do
    sign_in(@admin)
    team = teams(:team_one)
    get team_team_data_sources_url team
    assert_redirected_to team
  end

  test 'should destroy data team source' do
    sign_in(@admin)
    assert_difference('TeamDataSource.count', -1) do
      # Not in use by any projects for teams(:one) - should be destroyed
      team_data_sources(:team_one_deaths_transaction).destroy
      delete team_data_source_path team_data_sources(:team_one_deaths_gold)
    end
  end

  test 'should not destroy data team source currently in use by team project(s)' do
    sign_in(@admin)
    assert_no_difference('TeamDataSource.count') do
      # In use by teams(:one) projects(:one) - should not be destroyed
      team_data_sources(:team_one_deaths_gold).destroy
    end
  end
=end
  test 'should create new team data source' do
    skip
    sign_in(@admin)
    assert_difference('TeamDataset.count') do
      post team_team_datasets_url teams(:team_ONE_member), params: { team_dataset:
                                        { dataset_id: dataset(:deaths_gold_standard) } }
    end
  end
end
