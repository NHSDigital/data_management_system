require 'test_helper'

class SetCurrentTeamTest < ActionDispatch::IntegrationTest
  test 'User who belongs to no teams has no team set and warning message shown' do
    login_and_accept_terms(users(:standard_user_no_teams))
    assert page.has_content? 'Welcome to Data Management System'
  end
end
