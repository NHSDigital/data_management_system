require 'test_helper'

class ProjectDashboardTest < ActionDispatch::IntegrationTest
  def setup
    @app_man = users(:application_manager_three)
    create_projects
  end

  test 'sign in and visit project page, odr user' do
    sign_in @app_man
    visit terms_and_conditions_path
    click_on 'Accept'
    visit dashboard_projects_path
    assert page.has_content?('Unassigned Projects')
    assert page.has_no_content?('Assigned Projects')

    within('#unassigned-projects') do
      assert page.has_selector?('table#projects-table tr', count: 6)
      within('#projects-table') do
        assert_equal 2, page.all(:xpath, './/tr[td[contains(., "ODR Application")]]').count
        assert_equal 3, page.all(:xpath, './/tr[td[contains(., "ODR EOI")]]').count
      end
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
