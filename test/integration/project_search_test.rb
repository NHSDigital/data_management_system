require 'test_helper'

class ProjectSearchTest < ActionDispatch::IntegrationTest
  def setup
    user = users(:dummy_project_owner)
    user.projects.destroy_all

    create_test_records

    sign_in user
    visit projects_path
  end

  test 'can search by project name' do
    expand_search_form

    within('#project_search_form') do
      fill_in 'search[name]', with: 'YARP'
      click_button 'Search'
    end

    within('#projects-table') do
      assert has_selector?('tbody tr', count: 3)
      assert has_selector?('tbody tr', text: 'search.ref.1')
      assert has_selector?('tbody tr', text: 'search.ref.2')
      assert has_selector?('tbody tr', text: 'search.ref.3')
    end
  end

  test 'can search by application_ref' do
    expand_search_form

    within('#project_search_form') do
      fill_in 'search[application_log]', with: 'search.ref.2'
      click_button 'Search'
    end

    within('#projects-table') do
      assert has_selector?('tbody tr', count: 1)
      assert has_selector?('tbody tr', text: 'search.ref.2')
    end
  end

  test 'can search by project type' do
    expand_search_form

    within('#project_search_form') do
      click_link(href: '#project_type_filters')

      within('#project_type_filters') do
        uncheck_all
        check 'ODR EOI'
      end

      click_button 'Search'
    end

    within('#projects-table') do
      assert has_selector?('tbody tr', count: 2)
      assert has_selector?('tbody tr', text: 'ODR EOI', count: 2)
    end
  end

  test 'can search by project owner' do
    user = users(:standard_user1)

    expand_search_form

    within('#project_search_form') do
      click_link(href: '#project_owner_filters')

      fill_in 'search[owner][first_name]', with: user.first_name
      fill_in 'search[owner][last_name]',  with: user.last_name
      click_button 'Search'
    end

    within('#projects-table') do
      assert has_selector?('tbody tr', count: 1)
      assert has_selector?('tbody tr', text: 'search.ref.4')
    end
  end

  test 'can search by project state' do
    project = Project.find_by(application_log: 'search.ref.3')
    state   = workflow_states(:amend)

    project.project_states.build(state: state) do |project_state|
      project_state.save!(validate: false)
    end

    expand_search_form

    within('#project_search_form') do
      click_link(href: '#project_state_filters')

      within('#project_state_filters') do
        uncheck_all
        check state.id
      end

      click_button 'Search'
    end

    within('#projects-table') do
      assert has_selector?('tbody tr', count: 1)
      assert has_selector?('tbody tr', text: 'search.ref.3')
    end
  end

  test 'can search by application manager' do
    expand_search_form

    within('#project_search_form') do
      click_link(href: '#project_assigned_user_filters')

      select 'Application Manager One', from: 'search[assigned_user_id]'
      click_button 'Search'
    end

    within('#projects-table') do
      assert has_selector?('tbody tr', count: 2)
      assert has_selector?('tbody tr', text: 'search.ref.2')
      assert has_selector?('tbody tr', text: 'search.ref.3')
    end
  end

  test 'filters are applied cumulatively' do
    expand_search_form

    within('#project_search_form') do
      fill_in 'Project Title', with: 'YARP'

      click_link(href: '#project_type_filters')

      within('#project_type_filters') do
        uncheck_all
        check 'ODR Application'
      end

      click_button 'Search'
    end

    within('#projects-table') do
      assert has_selector?('tbody tr', count: 1)
      assert has_selector?('tbody tr', text: 'search.ref.3')
    end
  end

  test 'filters can be a little fuzzy and case insensitive' do
    user = users(:standard_user1)

    expand_search_form

    within('#project_search_form') do
      fill_in 'search[name]', with: 'ar'
      fill_in 'search[application_log]', with: '.Ref.'

      click_link(href: '#project_owner_filters')
      fill_in 'search[owner][first_name]', with: user.first_name.upcase
      fill_in 'search[owner][last_name]',  with: user.last_name.downcase

      click_button 'Search'
    end

    within('#projects-table') do
      assert has_selector?('tbody tr', count: 1)
      assert has_selector?('tbody tr', text: 'search.ref.4')
    end
  end

  test 'project dashboard search' do
    sign_out :user
    sign_in users(:application_manager_one)

    visit dashboard_projects_path

    expand_search_form

    within('#project_search_form') do
      fill_in 'search[name]', with: 'narp'
      click_button :submit
    end

    assert_equal dashboard_projects_path, current_path
    assert has_no_content? 'My Projects'
    assert has_no_content? 'Assigned Projects'
    assert has_content? 'Unassigned Projects'
    assert has_content? 'All Projects'

    within('#unassigned-projects') do
      assert has_selector?('tbody tr', count: 1)
      assert has_selector?('tbody tr', text: 'NARP')
    end

    within('#all-projects') do
      assert has_selector?('tbody tr', count: 1)
      assert has_selector?('tbody tr', text: 'NARP')
    end
  end

  test 'project dashboard search assigned' do
    user    = users(:application_manager_one)
    project = Project.find_by(name: 'NARP')

    project.update!(assigned_user: user)

    sign_out :user
    sign_in user

    visit dashboard_projects_path

    expand_search_form

    assert has_no_content? 'My Projects'
    assert has_content? 'Assigned Projects'
    assert has_content? 'Unassigned Projects'
    assert has_content? 'All Projects'

    within('#project_search_form') do
      fill_in 'search[name]', with: 'narp'
      click_button :submit
    end

    assert_equal dashboard_projects_path, current_path
    assert has_no_content? 'My Projects'
    assert has_content? 'Assigned Projects'
    assert has_no_content? 'Unassigned Projects'
    assert has_content? 'All Projects'
  end

  private

  def expand_search_form
    find('[data-target="#project_search_content"].collapsed').click
  end

  def uncheck_all
    all('input[type="checkbox"]').each(&:uncheck)
  end

  def create_test_records
    create_project(
      project_type: project_types(:project),
      name: 'YARP',
      project_purpose: 'For testing of search behaviour',
      application_log: 'search.ref.1',
      owner: users(:dummy_project_owner),
      assigned_user: users(:application_manager_two)
    )

    create_project(
      project_type: project_types(:eoi),
      name: 'YARP',
      project_purpose: 'For testing of search behaviour',
      application_log: 'search.ref.2',
      owner: users(:dummy_project_owner),
      assigned_user: users(:application_manager_one)
    )

    create_project(
      project_type: project_types(:application),
      name: 'YARP',
      project_purpose: 'For testing of search behaviour',
      application_log: 'search.ref.3',
      owner: users(:dummy_project_owner),
      assigned_user: users(:application_manager_one)
    )

    create_project(
      project_type: project_types(:eoi),
      name: 'NARP',
      project_purpose: 'For testing of search behaviour',
      application_log: 'search.ref.4',
      owner: users(:standard_user1)
    ).grants.create(
      user: users(:dummy_project_owner),
      roleable: project_roles(:contributor)
    )
  end
end
