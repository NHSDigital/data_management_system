require 'test_helper'

class CasApplicationFormTest < ActionDispatch::IntegrationTest
  test 'load form elements properly' do
    sign_in users(:odr_user) # CAS user role has not been set
    visit new_cas_application_path
    # form legend
    assert page.has_content?('Requester Details')
    assert page.has_content?('Account Details')
    assert page.has_content?('Permissions')
    assert page.has_content?('Declarations')
    assert page.has_button?('Create Application')

    # form label translated by i18n
    assert page.has_content?('First name')
    assert page.has_content?('Preferred username')

    # content loading from lookup table
    assert page.has_content?(lookups_cas_dataset(1).value)
    assert page.has_content?(lookups_cas_declaration(1).value)

    # Access level display as 3 accordions
    assert page.has_content?('Access level 1')
    assert page.has_content?('Access level 2')
    assert page.has_content?('Access level 3')
    assert page.has_selector?('.panel-group', count: 3)
  end

  test 'perseve user choice when loading edit form' do
    sign_in users(:odr_user) # CAS user role has not been set
    ca = CasApplication.create(
      firstname: 'John',
      surname: 'Smith',
      extra_datasets: %w[1 3 5],
      declaration: %w[1Yes 2No 4Yes]
    )
    visit edit_cas_application_path(ca)
    assert page.has_field?('First name', with: ca.firstname)
    assert page.has_field?('Surname', with: ca.surname)

    assert page.has_checked_field?('cas_application_datasets_1')
    assert page.has_checked_field?('cas_application_datasets_3')
    assert page.has_checked_field?('cas_application_datasets_5')
    assert page.has_unchecked_field?('cas_application_datasets_2')
    assert page.has_unchecked_field?('cas_application_datasets_4')

    assert page.has_field?('cas_application_declaration_1', with: '1Yes')
    assert page.has_field?('cas_application_declaration_2', with: '2No')
    assert page.has_field?('cas_application_declaration_3', with: '')
    assert page.has_field?('cas_application_declaration_4', with: '4Yes')
    assert page.has_field?('cas_application_declaration_5', with: '')

    assert page.has_button?('Update Application')
  end
end