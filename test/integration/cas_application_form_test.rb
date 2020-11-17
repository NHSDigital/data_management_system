require 'test_helper'

class CasApplicationFormTest < ActionDispatch::IntegrationTest
  test 'load form elements properly' do
    sign_in users(:standard_user) # CAS user role has not been set
    visit new_project_path(project: { project_type_id: project_types(:cas).id })

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
    assert page.has_content?('Extra CAS Dataset')
    assert page.has_content?(lookups_cas_declaration(1).value)

    # Access level display as 3 accordions
    assert page.has_content?('Access level 1')
    assert page.has_content?('Access level 2')
    assert page.has_content?('Access level 3')
    assert page.has_selector?('.panel-group', count: 3)
  end

  test 'perseve user choice when loading edit form' do
    sign_in users(:odr_user) # CAS user role has not been set
    application = Project.new.tap do |app|
      app.owner = users(:odr_user)
      app.project_type = project_types(:cas)
      app.build_cas_application_fields(firstname: 'John', surname: 'Smith',
                                       declaration: %w[1Yes 2No 4Yes])
      app.dataset_ids = Dataset.cas.pluck(:id)
      app.save!
    end

    visit edit_project_path(application)
    assert has_field?('First name', with: application.cas_application_fields.firstname)
    assert has_field?('Surname', with: application.cas_application_fields.surname)

    Dataset.cas.pluck(:id).each do |id|
      assert has_checked_field?("project_dataset_ids_#{id}")
    end

    assert has_field?('cas_application_declaration_1', with: '1Yes')
    assert has_field?('cas_application_declaration_2', with: '2No')
    assert has_field?('cas_application_declaration_3', with: '')
    assert has_field?('cas_application_declaration_4', with: '4Yes')
    assert has_field?('cas_application_declaration_5', with: '')

    assert has_button?('Update Application')
  end
end