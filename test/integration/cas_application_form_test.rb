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
      app.build_cas_application_fields(address: 'Fake Street', organisation: 'PHE',
                                       declaration: %w[1Yes 2No 4Yes])
      app.dataset_ids = Dataset.cas.pluck(:id)
      app.save!
    end

    visit edit_project_path(application)
    assert has_field?('Full physical addresses & postcodes CAS will be accessed from',
                      with: application.cas_application_fields.address)
    assert has_field?('Organisation employing user to do CAS work',
                      with: application.cas_application_fields.organisation)

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

  test 'some fields should only be viewable to application owner' do
    sign_in users(:no_roles)

    visit new_project_path(project: { project_type_id: project_types(:cas).id })

    assert has_content?('Contract start date')
    assert has_content?('Contract end date')
    assert has_content?('Preferred username')
    assert has_content?('Full physical addresses & postcodes CAS will be accessed from')
    assert has_content?('N3 IP address CAS will be accessed from')
    assert has_content?('I have completed the relevant data access forms for the ONS incidence ' \
                        'dataset')

    application = create_cas_project(owner: users(:no_roles))
    application.build_cas_application_fields(address: 'Fake Street', organisation: 'PHE',
                                             declaration: %w[1Yes 2No 4Yes])
    application.dataset_ids = Dataset.cas.pluck(:id)
    application.save!

    visit project_path(application)

    assert has_content?('Contract start date')
    assert has_content?('Contract end date')
    assert has_content?('Preferred username')
    assert has_content?('Full physical addresses & postcodes CAS will be accessed from')
    assert has_content?('N3 IP address CAS will be accessed from')
    assert has_content?('I have completed the relevant data access forms for the ONS incidence ' \
                        'dataset')

    sign_out users(:no_roles)

    sign_in users(:cas_dataset_approver)

    application.transition_to!(workflow_states(:submitted))

    visit project_path(application)

    assert has_no_content?('Contract start date')
    assert has_no_content?('Contract end date')
    assert has_no_content?('Preferred username')
    assert has_no_content?('Full physical addresses & postcodes CAS will be accessed from')
    assert has_no_content?('N3 IP address CAS will be accessed from')
    assert has_no_content?('I have completed the relevant data access forms for the ONS ' \
                            'incidence dataset')
  end

  test 'requestor details section should be readonly' do
    sign_in users(:no_roles)

    visit new_project_path(project: { project_type_id: project_types(:cas).id })

    within('#first_name') do
      assert has_css?('.form-control-static')
    end
    within('#email') do
      assert has_css?('.form-control-static')
    end
    # Other sections should not be effected and should be editable
    within('#organisation') do
      assert has_no_css?('.form-control-static')
    end

    assert has_content?('These are your user details that will form part of your application. If ' \
                        'you wish to change these there will be the chance to edit this in the ' \
                        'My Account section after you create this application.')

    application = create_cas_project(owner: users(:no_roles))
    application.build_cas_application_fields(address: 'Fake Street', organisation: 'PHE',
                                             declaration: %w[1Yes 2No 4Yes])
    application.dataset_ids = Dataset.cas.pluck(:id)
    application.save!

    visit project_path(application)

    click_link('Edit')

    within('#first_name') do
      assert has_css?('.form-control-static')
    end
    within('#email') do
      assert has_css?('.form-control-static')
    end
    # Other sections should not be effected and should be editable
    within('#organisation') do
      assert has_no_css?('.form-control-static')
    end
  end

  test 'should disable submit button and show transition error if user details not complete' do
    sign_in users(:no_roles)

    visit new_project_path(project: { project_type_id: project_types(:cas).id })

    click_button('Create Application')

    assert has_button?('Submit', disabled: true)
    assert has_content?('some user details are not complete - please visit the My Account page ' \
                        'to update')
  end
end
