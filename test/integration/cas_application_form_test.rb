require 'test_helper'

class CasApplicationFormTest < ActionDispatch::IntegrationTest
  test 'load form elements properly' do
    sign_in users(:no_roles)
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
    assert page.has_content?('Extra Datasets')

    assert page.has_selector?("#dataset_#{dataset(83).id}_row")
    assert page.has_selector?("#dataset_#{dataset(84).id}_row")
    # not a cas_extras dataset
    assert page.has_no_selector?("#dataset_#{dataset(85).id}_row")

    within "#dataset_#{dataset(83).id}_row" do
      assert has_selector?('#level_1_check_box')
      assert has_selector?('#level_1_expiry_datepicker')
      assert has_selector?('#level_2_check_box')
      assert has_selector?('#level_2_expiry_datepicker')
      # level 3 not in datasets levels
      assert has_no_selector?('#level_3_check_box')
      assert has_no_selector?('#level_3_expiry_datepicker')
    end

    within "#dataset_#{dataset(84).id}_row" do
      # level 1 not in datasets levels
      assert has_no_selector?('#level_1_check_box')
      assert has_no_selector?('#level_1_expiry_datepicker')
      assert has_selector?('#level_2_check_box')
      assert has_selector?('#level_2_expiry_datepicker')
      assert has_selector?('#level_3_check_box')
      assert has_selector?('#level_3_expiry_datepicker')
    end

    assert page.has_content?(lookups_cas_declaration(1).value)

    # Access level display as 3 accordions
    assert page.has_content?('Access level 1')
    assert page.has_content?('Access level 2')
    assert page.has_content?('Access level 3')
    assert page.has_selector?('.panel-group', count: 3)
  end

  test 'preserve user choice when loading edit form' do
    sign_in users(:no_roles)
    application = Project.new.tap do |app|
      app.owner = users(:no_roles)
      app.project_type = project_types(:cas)
      app.build_cas_application_fields(address: 'Fake Street', organisation: 'PHE',
                                       declaration: %w[1Yes 2No 4Yes])
      project_dataset = ProjectDataset.create(dataset: dataset(83), terms_accepted: true)
      app.project_datasets << project_dataset
      pdl1 = ProjectDatasetLevel.new(access_level_id: 1, expiry_date: Time.zone.today + 1.week, selected: true)
      pdl2 = ProjectDatasetLevel.new(access_level_id: 2, expiry_date: Time.zone.today + 1.week, selected: true)
      project_dataset.project_dataset_levels << pdl1
      project_dataset.project_dataset_levels << pdl2
      app.save!
    end

    visit edit_project_path(application)

    assert has_field?('Full physical addresses & postcodes CAS will be accessed from',
                      with: application.cas_application_fields.address)
    assert has_field?('Organisation employing user to do CAS work',
                      with: application.cas_application_fields.organisation)

    within "#dataset_#{application.project_datasets.first.dataset.id}_row" do
      assert has_checked_field?('level_1_check_box')
      assert has_checked_field?('level_2_check_box')
      assert_not has_checked_field?('level_3_check_box')
    end

    assert has_field?('cas_application_declaration_1', with: '1Yes')
    assert has_field?('cas_application_declaration_2', with: '2No')
    assert has_field?('cas_application_declaration_3', with: '')
    assert has_field?('cas_application_declaration_4', with: '4Yes')
    assert has_field?('cas_application_declaration_5', with: '')

    assert has_button?('Update Application')
  end

  test 'display dataset matrix correctly in readonly' do
    sign_in users(:no_roles)
    application = Project.new.tap do |app|
      app.owner = users(:no_roles)
      app.project_type = project_types(:cas)
      project_dataset = ProjectDataset.create(dataset: dataset(83), terms_accepted: true)
      app.project_datasets << project_dataset
      pdl1 = ProjectDatasetLevel.new(access_level_id: 1, expiry_date: Time.zone.today,
                                     selected: true)
      project_dataset.project_dataset_levels << pdl1
      app.save!
    end

    visit project_path(application)

    within "#dataset_#{application.project_datasets.first.dataset.id}_row" do
      within '#level_1_selected' do
        assert find('.glyphicon-ok')
      end
      within '#level_2_selected' do
        assert find('.glyphicon-remove')
      end
      within '#level_3_selected' do
        assert has_no_content?
      end
      within '#level_1_expiry_date' do
        assert has_content?("#{Time.zone.today.strftime('%d/%m/%Y')} (requested)")
      end
      within '#level_2_expiry_date' do
        assert has_no_content?
      end
      within '#level_3_expiry_date' do
        assert has_no_content?
      end
    end
  end

  test 'ensure that project_datasets and levels are built correctly from the form' do
    sign_in users(:no_roles)
    visit new_project_path(project: { project_type_id: project_types(:cas).id })

    within "#dataset_#{dataset(83).id}_row" do
      find(:css, '#level_1_check_box').set(true)
      find(:css, '#level_1_expiry_datepicker').set('01/01/2022')
    end
    within "#dataset_#{dataset(84).id}_row" do
      find(:css, '#level_2_check_box').set(true)
      find(:css, '#level_2_expiry_datepicker').set('01/01/2022')
      find(:css, '#level_3_check_box').set(true)
      find(:css, '#level_3_expiry_datepicker').set('01/01/2022')
    end

    click_button('Create Application')

    project_datasets = Project.last.project_datasets

    assert_equal project_datasets.size, 2
    assert_equal project_datasets.find_by(dataset_id: 83).project_dataset_levels.size, 1
    assert_equal project_datasets.find_by(dataset_id: 83).project_dataset_levels.first.access_level_id, 1
    assert project_datasets.find_by(dataset_id: 83).project_dataset_levels.all?(&:selected)
    assert_equal project_datasets.find_by(dataset_id: 84).project_dataset_levels.size, 2
    assert project_datasets.find_by(dataset_id: 84).project_dataset_levels.all?(&:selected)

    visit edit_project_path(Project.last.id)

    within "#dataset_#{dataset(83).id}_row" do
      find(:css, '#level_1_check_box').set(false)
    end

    click_button('Update Application')

    assert_equal project_datasets.size, 1
    assert_equal project_datasets.first.dataset_id, 84

    visit edit_project_path(Project.last.id)

    within "#dataset_#{dataset(83).id}_row" do
      find(:css, '#level_2_check_box').set(true)
    end

    click_button('Update Application')

    assert_equal project_datasets.size, 2
    assert_equal project_datasets.find_by(dataset_id: 83).project_dataset_levels.size, 1
    assert_equal project_datasets.find_by(dataset_id: 83).project_dataset_levels.first.access_level_id, 2
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
