require 'test_helper'

class HomePageTest < ActionDispatch::IntegrationTest
  test 'should return projects dashboard page for odr non-standard user' do
    sign_in users(:application_manager_three)

    visit root_path
    assert has_content?('Projects Dashboard')

    within '.navbar' do
      click_link('Data Management System')
    end
    assert_equal home_index_path, current_path
  end

  test 'should return projects index page for cas role user' do
    sign_in users(:cas_manager)

    visit root_path
    assert has_content?('Listing Projects')

    within '.navbar' do
      click_link('Data Management System')
    end
    assert_equal home_index_path, current_path
  end

  test 'should return home index page for standard user' do
    sign_in users(:no_roles)

    visit root_path
    assert has_content?('Welcome to Data Management System')

    within '.navbar' do
      click_link('Data Management System')
    end
    assert_equal home_index_path, current_path
  end

  test 'should visit Cas application form when clicking CAS Application Form link if in test' do
    sign_in users(:no_roles)

    visit root_path
    assert has_content?('Welcome to Data Management System')

    click_link('CAS Application Form')

    assert has_content?('New CAS Application')
  end

  test 'should visit Cas application form when clicking CAS Application Form link if in beta' do
    Mbis.stubs(:stack).returns('beta')
    Mbis.stack.stubs(:live?).returns(false)
    sign_in users(:no_roles)

    visit root_path
    assert has_content?('Welcome to Data Management System')

    click_link('CAS Application Form')

    assert has_content?('New CAS Application')
  end

  test 'should not visit Cas application form when clicking CAS Application Form link if in live' do
    Mbis.stubs(:stack).returns('live')
    Mbis.stack.stubs(:live?).returns(true)
    sign_in users(:no_roles)

    visit root_path
    assert has_content?('Welcome to Data Management System')

    assert has_no_content?('CAS Application Form')
  end

  test 'should visit projects page when clicking My Applications link' do
    sign_in users(:no_roles)

    visit root_path
    assert has_content?('Welcome to Data Management System')

    click_link('My Applications')

    assert_equal projects_path, current_path
  end

  test 'should visit datasets page when clicking ODR Datasets link' do
    sign_in users(:no_roles)

    visit root_path
    assert has_content?('Welcome to Data Management System')

    click_link('ODR Datasets')

    assert_equal datasets_path, current_path
  end
end
