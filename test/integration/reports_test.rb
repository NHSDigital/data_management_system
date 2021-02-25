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
end
