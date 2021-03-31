require 'test_helper'

class ProjectDashboardTest < ActionDispatch::IntegrationTest
  def setup
    create_projects
  end

  test 'sign in and visit project page, application manager' do
    sign_in users(:application_manager_three)
    cas_project = create_project(project_type: project_types(:cas),
                                 owner: users(:application_manager_three))
    cas_project2 = create_project(project_type: project_types(:cas),
                                  owner: users(:standard_user))
    eoi_project = create_project(project_type: project_types(:eoi), project_purpose: 'test',
                                 owner: users(:application_manager_three))
    visit terms_and_conditions_path
    click_on 'Accept'
    visit dashboard_projects_path
    within('#projects-table', match: :first) do
      assert has_content?('Project Title')
    end
    assert has_content?('My Projects')
    assert has_content?('Unassigned Projects')
    assert has_content?('All Projects')
    assert has_no_content?('Assigned Projects')
    # (Senior) Application Manager should not see filter as they can only read ODR
    assert has_no_content?('Application Filter')

    within('#my-projects') do
      assert has_content?(eoi_project.id.to_s)
      assert has_content?(cas_project.id.to_s)
      assert has_no_content?(cas_project2.id.to_s)
    end

    within('#all-projects') do
      assert has_content?('ODR Application')
      assert has_content?('ODR EOI')
      assert has_no_content?('MBIS Application')
      assert has_no_content?('CAS Application')
    end

    within('#unassigned-projects') do
      assert has_content?('ODR Application')
      assert has_content?('ODR EOI')
      assert has_no_content?('MBIS Application')
      assert has_no_content?('CAS Application')
    end
  end

  test 'sign in and visit project page, odr role' do
    sign_in users(:odr_user)
    cas_project = create_project(project_type: project_types(:cas),
                                 owner: users(:odr_user))
    cas_project2 = create_project(project_type: project_types(:cas),
                                  owner: users(:standard_user))
    eoi_project = create_project(project_type: project_types(:eoi), project_purpose: 'test',
                                 owner: users(:odr_user))
    visit terms_and_conditions_path
    click_on 'Accept'
    visit dashboard_projects_path

    assert has_content?('Unassigned Projects')
    assert has_content?('My Projects')
    assert has_content?('All Projects')
    assert has_no_content?('Assigned Projects')
    # ODR role should see filter as they can read both MBIS and ODR
    assert has_content?('Application Filter')

    # (Senior) Application Manager should only see filter on My Projects and ODR should be default
    within('#my-projects') do
      assert has_content?(eoi_project.id.to_s)
      assert has_content?(cas_project.id.to_s)
      assert has_no_content?(cas_project2.id.to_s)
    end

    within('#all-projects') do
      assert has_content?('ODR Application')
      assert has_content?('ODR EOI')
      assert has_no_content?('MBIS Application')
      assert has_no_content?('CAS Application')
    end

    within('#unassigned-projects') do
      assert has_content?('ODR Application')
      assert has_content?('ODR EOI')
      assert has_no_content?('MBIS Application')
      assert has_no_content?('CAS Application')
    end

    click_button('Application Filter')
    click_link('All applications')

    within('#my-projects') do
      assert has_content?(eoi_project.id.to_s)
      assert has_content?(cas_project.id.to_s)
      assert has_no_content?(cas_project2.id.to_s)
    end

    within('#all-projects') do
      assert has_no_content?(cas_project.id.to_s)
      assert has_no_content?('CAS Application')
      assert has_content?('ODR Application')
      assert has_content?('ODR EOI')
      assert has_content?('MBIS Application')
    end

    within('#unassigned-projects') do
      assert has_content?('MBIS Application')
      assert has_no_content?('CAS Application')
      assert has_content?('ODR Application')
      assert has_content?('ODR EOI')
    end

    click_button('Application Filter')
    click_link('MBIS applications')

    within('#my-projects') do
      assert has_content?(eoi_project.id.to_s)
      assert has_content?(cas_project.id.to_s)
      assert has_no_content?(cas_project2.id.to_s)
    end

    within('#all-projects') do
      assert has_no_content?(cas_project.id.to_s)
      assert has_no_content?('CAS Application')
      assert has_no_content?('ODR Application')
      assert has_no_content?('ODR EOI')
      assert has_content?('MBIS Application')
    end

    within('#unassigned-projects') do
      assert has_content?('MBIS Application')
      assert has_no_content?('CAS Application')
      assert has_no_content?('ODR Application')
      assert has_no_content?('ODR EOI')
    end

    click_button('Application Filter')
    click_link('ODR applications')

    within('#my-projects') do
      assert has_content?(eoi_project.id.to_s)
      assert has_content?(cas_project.id.to_s)
      assert has_no_content?(cas_project2.id.to_s)
    end

    within('#all-projects') do
      assert has_content?('ODR Application')
      assert has_content?('ODR EOI')
      assert has_no_content?('MBIS Application')
      assert has_no_content?('CAS Application')
    end

    within('#unassigned-projects') do
      assert has_content?('ODR Application')
      assert has_content?('ODR EOI')
      assert has_no_content?('MBIS Application')
      assert has_no_content?('CAS Application')
    end
  end

  test 'sign in and visit project page, mbis delegate' do
    sign_in users(:delegate_user1)
    cas_project = create_project(project_type: project_types(:cas),
                                 owner: users(:delegate_user1))
    cas_project2 = create_project(project_type: project_types(:cas),
                                  owner: users(:standard_user))
    mbis_project = create_project(project_type: project_types(:project), project_purpose: 'test',
                                  owner: users(:delegate_user1))
    visit terms_and_conditions_path
    click_on 'Accept'
    visit dashboard_projects_path

    assert has_content?('Unassigned Projects')
    assert has_content?('My Projects')
    assert has_content?('All Projects')
    assert has_no_content?('Assigned Projects')
    # MBIS Delegate should not see filter as they can only read MBIS
    assert has_no_content?('Application Filter')

    within('#my-projects') do
      assert has_content?(mbis_project.id.to_s)
      assert has_content?(cas_project.id.to_s)
      assert has_no_content?(cas_project2.id.to_s)
    end

    within('#all-projects') do
      assert has_no_content?('ODR Application')
      assert has_no_content?('ODR EOI')
      assert has_content?('MBIS Application')
      assert has_no_content?('CAS Application')
    end

    within('#unassigned-projects') do
      assert has_no_content?('ODR Application')
      assert has_no_content?('ODR EOI')
      assert has_content?('MBIS Application')
      assert has_no_content?('CAS Application')
    end
  end

  test 'sign in and visit project page, mbis applicant' do
    sign_in users(:standard_user1)
    cas_project = create_project(project_type: project_types(:cas),
                                 owner: users(:standard_user1))
    cas_project2 = create_project(project_type: project_types(:cas),
                                  owner: users(:no_roles))
    mbis_project = create_project(project_type: project_types(:project), project_purpose: 'test',
                                  owner: users(:standard_user1))
    visit terms_and_conditions_path
    click_on 'Accept'
    visit dashboard_projects_path

    assert has_content?('Unassigned Projects')
    assert has_content?('My Projects')
    assert has_content?('All Projects')
    assert has_no_content?('Assigned Projects')
    # MBIS Delegate should not see filter as they can only read MBIS
    assert has_no_content?('Application Filter')

    within('#my-projects') do
      assert has_content?(mbis_project.id.to_s)
      assert has_content?(cas_project.id.to_s)
      assert has_no_content?(cas_project2.id.to_s)
    end

    within('#all-projects') do
      assert has_no_content?('ODR Application')
      assert has_no_content?('ODR EOI')
      assert has_content?('MBIS Application')
      assert has_no_content?('CAS Application')
    end

    within('#unassigned-projects') do
      assert has_no_content?('ODR Application')
      assert has_no_content?('ODR EOI')
      assert has_content?('MBIS Application')
      assert has_no_content?('CAS Application')
    end
  end

  private

  def create_projects
    %w[1 2 3].each do |n|
      create_project(name: "Project Type #{n}", project_type: project_types(:eoi),
                     project_purpose: 'test')
    end
    create_project(name: 'Project Type Application', project_type: project_types(:application))
  end
end
