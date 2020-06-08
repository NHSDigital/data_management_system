require 'test_helper'

# Not sure this is needed - a lot of work with current_team would need to be undone
class DoesNotNeedToSelectTeam < ActionDispatch::IntegrationTest
  test 'Admin user who belongs to no teams should see notifications' do
    login_and_accept_terms(users(:admin_user))
    assert page.has_no_content? 'You are not currently a member of any teams'
  end

  # test 'Admin user who belongs to one teams has team set and shows notifications' do
  #   login_and_accept_terms(users(:standard_user_one_team))
  #   assert page.has_content? <<~FLASH
  #     Current team has been set to: team_one_member
  #   FLASH
  #   assert page.has_content? 'Notifications'
  # end
  #
  # test 'User who belongs to many teams has no team set and shows available teams' do
  #   login_and_accept_terms(users(:standard_user2))
  #   assert page.has_content? <<~FLASH
  #     Please set an Active Team for your session
  #   FLASH
  #   assert page.has_content? 'team_many_member'
  #   assert page.has_content? 'team_one'
  # end
  #
  # test 'User who belongs to many teams can set new active team' do
  #   login_and_accept_terms(users(:standard_user2))
  #   assert page.has_content? <<~FLASH
  #     Please set an Active Team for your session
  #   FLASH
  #   click_on 'Set team_many_member as active team'
  #   assert page.has_content? <<~FLASH
  #     Current team has been set to: team_many_member
  #   FLASH
  #
  #   # Change active team
  #   visit user_path(users(:standard_user2))
  #   page.find('#user-dropdown').click
  #   click_link 'Change active team'
  #   click_on 'Set team_one as active team'
  #   assert page.has_content? <<~FLASH
  #     Current team has been set to: team_one
  #   FLASH
  # end
end
