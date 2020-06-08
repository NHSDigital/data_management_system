require 'test_helper'

class CreateAndEditUserTest < ActionDispatch::IntegrationTest
  def setup
    @admin = users(:admin_user)
    login_and_accept_terms(@admin)
  end

  test 'creating a user should generate password' do
    visit users_path
    click_link 'Create New User'

    fill_in 'user_first_name', with: 'MICKEY'
    fill_in 'user_last_name',  with: ''
    fill_in 'user_username',  with: 'testname'
    fill_in 'user_email',      with: 'test_email@phe.gov.uk'
    fill_in 'user_telephone',  with: '01223213499'
    select 'AA', from: 'user_grade'
    select 'Directorate 1', from: 'user_directorate_id'
    select 'Division 1 from directorate 1', from: 'user_division_id'
    fill_in 'user_location',   with: 'Cambridge'
    fill_in 'user_job_title',  with: 'The Boss'
    fill_in 'user_notes',      with: 'Some notes about this test user'

    click_button 'Save'
    assert page.has_content?("can't be blank") # last_name was blank

    fill_in 'user_last_name', with: 'MOUSE'
    click_button 'Save'
    assert page.has_content?('User was successfully created')
    assert page.has_text?('MICKEY')
    assert page.has_text?('MOUSE')

    visit user_path(User.last)
    assert page.has_content?('AA')

  end

  test 'edit user' do
    visit users_path

    page.find('#users_table').click_link('Edit', match: :first)
    fill_in 'user_first_name', with: ''
    click_button 'Save'
    assert page.has_content?("can't be blank") # first_name was blank
    fill_in 'user_first_name', with: 'NEW FIRST NAME'

    click_button 'Save'
    assert page.has_content?('New First Name')
  end

  test 'can update a user team grants' do
    team = teams(:team_one)
    user = users(:standard_user)

    user.grants.create!(team: team, roleable: team_roles(:mbis_applicant))

    visit user_path(user)
    assert_equal user_path(user), current_path

    click_link('Roles')
    assert_equal user_grants_path(user), current_path

    page.find('#user-team-grants').click_link 'Edit'
    assert_equal edit_team_user_grants_path(user), current_path

    assert_difference('Grant.count', +2) do
      page.check("grants_TeamRole_#{teams(:team_one).id}_#{TeamRole.fetch(:read_only).id}")
      page.check("grants_TeamRole_#{teams(:team_one).id}_#{TeamRole.fetch(:odr_applicant).id}")
      find_button('Update Roles').click

      assert page.has_content?('User grants updated')
    end
  end

  test 'can update a user system grants' do
    visit users_path

    page.find('#users_table').click_link('Details', match: :first)
    click_link('Roles')
    page.find('#user-system-grants').click_link 'Edit'

    assert_difference('Grant.count', +1) do
      page.check("grants_SystemRole_system_#{SystemRole.fetch(:odr).id}")
      find_button('Update Roles').click
    end
  end
end
