require 'test_helper'

class CanManageUsersTest < ActionDispatch::IntegrationTest
  def setup
    @admin = users(:admin_user)
    login_and_accept_terms(@admin)
  end

  test 'can create a user' do
    visit users_path
    click_link 'Create New User'
    fill_in_user_data
    click_button 'Save'

    # Test that User details have been populated.
    assert page.has_content?('John Johnson')
    assert page.has_content?('johnjohnson@phe.gov.uk')
    assert page.has_content?(/User was successfully created/)

    # Edit the user after creating:
    page.find('#users_table').find('tr', text: 'John Johnson').click_link('Edit')
    fill_in 'user_first_name', with: 'Bob'
    click_button 'Save'

    assert page.has_content? <<~FLASH
      User was successfully updated.
    FLASH

    assert page.has_content?('Bob Johnson')
    assert page.has_no_content?('John Johnson')
  end

  test 'should be able to search for user' do
    visit users_path

    within('#search-form') do
      fill_in 'search[name]', with: 'dummy'
      click_button :submit
    end

    assert_equal users_path, current_path
    within('table') do
      assert has_text?('fizzy')
      assert has_no_text?('Manager')
    end
  end

  test 'mandatory fields should be highlighted' do
    visit users_path
    click_link 'Create New User'
    page.assert_selector('.form-control.mandatory', count: 4)
  end

  private

  def fill_in_user_data
    fill_in 'user_first_name', with: 'John'
    fill_in 'user_last_name',  with: 'Johnson'
    fill_in 'user_username',  with: 'johnjohnson'
    fill_in 'user_email',      with: 'johnjohnson@phe.gov.uk'
    fill_in 'user_telephone',  with: '01223 329474'
    select 'AA', from: 'user_grade'
    select 'Directorate 1', from: 'user_directorate_id'
    select 'Division 1 from directorate 1', from: 'user_division_id'
    fill_in 'user_location',   with: 'New York'
    fill_in 'user_job_title',  with: 'Tea boy'
    select 'Active',           from: 'user_z_user_status_id'
  end
end
