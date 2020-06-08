require 'test_helper'

class ProjectAttachmentsControllerTest < ActionDispatch::IntegrationTest
  # TODO: have added integration test in create_and_edit_project_test
  def setup
    @user = users(:standard_user_one_team)
  end
end
