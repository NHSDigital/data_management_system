require 'test_helper'

class ReportsTest < ActionDispatch::IntegrationTest
  def setup
    @admin = users(:admin_user)
    login_and_accept_terms(@admin)
  end

  test 'data in report 1 is correct' do
    visit report1_path
    assert has_content? 'Births Gold Standard'
    assert page.has_selector?('table tr', count: Project.of_type_project.count + 1)
    click_on 'CSV'
    wait_for_download
    assert_equal 1, downloads.count
  end

  # TODO: Report2 is deprecated and due to be removed in the future.
  test 'data in report 2 is correct' do
    skip

    visit report2_path
    assert page.has_selector?('table tr', count: Comment.count + 1)
    click_on 'CSV'
    wait_for_download
    assert_equal 1, downloads.count
  end

  test 'user can download report they have been granted access to' do
    sign_out @admin
    sign_in users(:application_manager_one)

    visit root_path

    within('.navbar') do
      click_link 'Reports'

      assert has_link?('ODR - My Workload')
      click_link('ODR - My Workload')

      wait_for_download
      assert_equal 1, downloads.count
    end
  end

  test 'user cannot download report have not been granted access to' do
    sign_out @admin
    sign_in users(:application_manager_one)

    visit root_path

    within('.navbar') do
      click_link 'Reports'
      assert has_no_link?('ODR - All Open Projects')
    end

    visit report_path(id: 'open_project_report')

    assert_equal root_path, current_path
    assert has_text?(/not authorized/i)
  end
end
