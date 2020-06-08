require 'test_helper'

class DirectoratesAndDivisionsManagementTest < ActionDispatch::IntegrationTest
  def setup
    @admin = users(:admin_user)
    login_and_accept_terms(@admin)
  end

  test 'creating a directorate ' do
    visit directorates_path
    click_link 'Add Directorate'

    fill_in 'directorate_name', with: 'My brand spanking new directorate'
    click_button 'Save'

    assert page.has_content?('My brand spanking new directorate')
  end

  test 'add a division to a directorate ' do
    visit directorates_path
    click_link('Add division', match: :first)
    fill_in 'division_name', with: 'My brand spanking new DIVISION'
    fill_in 'division_head_of_profession', with: 'Phil Connors'
    click_button 'Save'

    assert page.has_content?('My brand spanking new DIVISION')
    assert page.has_content?('Phil Connors')
  end

  test 'delete a directorate not attached to team or project' do
    visit directorates_path
    assert_difference('Directorate.count', -1) do
      accept_prompt do
        page.find('#directorates_information').
          find('tr', text: 'Directorate 2').
          click_link('Delete')
      end

      assert page.has_text? 'Directorate was successfully deleted.'
    end
  end

  test 'delete a directorate attached to team' do
    visit directorates_path
    assert_difference('Directorate.count', 0) do
      accept_prompt do
        directorate2_row = page.find('#directorates_information').find('tr', text: 'Directorate 1')
        directorate2_row.click_link('Delete')
      end
    end
    assert page.has_content?("You can't delete directorate as it assigned to active user or active teams")
  end

end
