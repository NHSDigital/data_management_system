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

    within('#extra_datasets') do
      assert page.has_selector?("#dataset_#{dataset(83).id}_row")
      assert page.has_selector?("#dataset_#{dataset(84).id}_row")
    end

    within('#default_datasets') do
      assert page.has_selector?("#dataset_#{dataset(85).id}_row")
      assert page.has_selector?("#dataset_#{dataset(86).id}_row")
    end

    within "#dataset_#{dataset(83).id}_row" do
      assert has_selector?("#dataset_#{dataset(83).id}_level_1_check_box")
      assert has_selector?("#dataset_#{dataset(83).id}_level_1_expiry_datepicker")
      assert has_selector?("#dataset_#{dataset(83).id}_level_2_check_box")
      assert has_selector?("#dataset_#{dataset(83).id}_level_2_expiry_datepicker")
      # level 3 not in datasets levels
      assert has_no_selector?("#dataset_#{dataset(83).id}_level_3_check_box")
      assert has_no_selector?("#dataset_#{dataset(83).id}_level_3_expiry_datepicker")
    end

    within "#dataset_#{dataset(84).id}_row" do
      # level 1 not in datasets levels
      assert has_no_selector?("#dataset_#{dataset(84).id}_level_1_check_box")
      assert has_no_selector?("#dataset_#{dataset(84).id}_level_1_expiry_datepicker")
      assert has_selector?("#dataset_#{dataset(84).id}_level_2_check_box")
      assert has_selector?("#dataset_#{dataset(84).id}_level_2_expiry_datepicker")
      assert has_selector?("#dataset_#{dataset(84).id}_level_3_check_box")
      assert has_selector?("#dataset_#{dataset(84).id}_level_3_expiry_datepicker")
    end
    within "#dataset_#{dataset(85).id}_row" do
      assert has_selector?("#dataset_#{dataset(85).id}_level_1_check_box")
      assert has_selector?("#dataset_#{dataset(85).id}_level_1_expiry_datepicker")
      assert has_selector?("#dataset_#{dataset(85).id}_level_2_check_box")
      assert has_selector?("#dataset_#{dataset(85).id}_level_2_expiry_datepicker")
      # level 3 not in datasets levels
      assert has_no_selector?("#dataset_#{dataset(85).id}_level_3_check_box")
      assert has_no_selector?("#dataset_#{dataset(85).id}_level_3_expiry_datepicker")
    end

    within "#dataset_#{dataset(86).id}_row" do
      # level 1 not in datasets levels
      assert has_no_selector?("#dataset_#{dataset(86).id}_level_1_check_box")
      assert has_no_selector?("#dataset_#{dataset(86).id}_level_1_expiry_datepicker")
      assert has_selector?("#dataset_#{dataset(86).id}_level_2_check_box")
      assert has_selector?("#dataset_#{dataset(86).id}_level_2_expiry_datepicker")
      assert has_selector?("#dataset_#{dataset(86).id}_level_3_check_box")
      assert has_selector?("#dataset_#{dataset(86).id}_level_3_expiry_datepicker")
    end

    within "#dataset_#{dataset(87).id}_row" do
      # level 1 and 3 not in datasets levels
      assert has_no_selector?("#dataset_#{dataset(87).id}_level_1_check_box")
      assert has_no_selector?("#dataset_#{dataset(87).id}_level_1_expiry_datepicker")
      assert has_selector?("#dataset_#{dataset(87).id}_level_2_check_box")
      assert has_selector?("#dataset_#{dataset(87).id}_level_2_expiry_datepicker")
      assert has_no_selector?("#dataset_#{dataset(87).id}_level_3_check_box")
      assert has_no_selector?("#dataset_#{dataset(87).id}_level_3_expiry_datepicker")
    end

    assert page.has_content?(lookups_cas_declaration(1).value)
  end

  test 'preserve user choice when loading edit form' do
    sign_in users(:no_roles)
    application = Project.new.tap do |app|
      app.owner = users(:no_roles)
      app.project_type = project_types(:cas)
      app.build_cas_application_fields(address: 'Fake Street', organisation: 'PHE',
                                       declaration: %w[1Yes 2No 4Yes])
      extra_project_dataset = ProjectDataset.create(dataset: dataset(83), terms_accepted: true)
      default_project_dataset = ProjectDataset.create(dataset: dataset(86), terms_accepted: true)
      app.project_datasets << extra_project_dataset
      app.project_datasets << default_project_dataset
      pdl1 = ProjectDatasetLevel.new(access_level_id: 1, expiry_date: Time.zone.today + 1.week, selected: true)
      pdl2 = ProjectDatasetLevel.new(access_level_id: 2, expiry_date: Time.zone.today + 1.week, selected: true)
      pdl3 = ProjectDatasetLevel.new(access_level_id: 2, expiry_date: Time.zone.today + 1.week, selected: true)
      pdl4 = ProjectDatasetLevel.new(access_level_id: 3, expiry_date: Time.zone.today + 1.week, selected: true)
      extra_project_dataset.project_dataset_levels << pdl1
      extra_project_dataset.project_dataset_levels << pdl2
      default_project_dataset.project_dataset_levels << pdl3
      default_project_dataset.project_dataset_levels << pdl4
      app.save!(validate: false)
    end

    visit edit_project_path(application)

    assert has_field?('Full physical addresses & postcodes CAS will be accessed from',
                      with: application.cas_application_fields.address)
    assert has_field?('Organisation employing user to do CAS work',
                      with: application.cas_application_fields.organisation)

    within "#dataset_#{application.project_datasets.find_by(dataset_id: 83).dataset.id}_row" do
      assert has_checked_field?("dataset_#{dataset(83).id}_level_1_check_box")
      assert_equal find("#dataset_#{dataset(83).id}_level_1_expiry_datepicker").value,
                   (Time.zone.today + 1.week).strftime('%d/%m/%Y')
      assert has_checked_field?("dataset_#{dataset(83).id}_level_2_check_box")
      assert has_no_checked_field?("dataset_#{dataset(83).id}_level_3_check_box")
    end

    within "#dataset_#{application.project_datasets.find_by(dataset_id: 86).dataset.id}_row" do
      assert has_no_checked_field?("dataset_#{dataset(86).id}_level_1_check_box")
      assert has_checked_field?("dataset_#{dataset(86).id}_level_2_check_box")
      assert_equal find("#dataset_#{dataset(86).id}_level_2_expiry_datepicker").value,
                   (Time.zone.today + 1.week).strftime('%d/%m/%Y')
      assert has_checked_field?("dataset_#{dataset(86).id}_level_3_check_box")
    end

    assert has_field?('cas_application_declaration_1', with: '1Yes')
    assert has_field?('cas_application_declaration_2', with: '2No')
    assert has_field?('cas_application_declaration_3', with: '')
    assert has_field?('cas_application_declaration_4', with: '4Yes')

    assert has_button?('Update Application')
  end

  test 'display dataset matrix correctly in readonly' do
    sign_in users(:no_roles)
    application = Project.new.tap do |app|
      app.owner = users(:no_roles)
      app.project_type = project_types(:cas)
      extra_project_dataset = ProjectDataset.create(dataset: dataset(83), terms_accepted: true)
      default_project_dataset = ProjectDataset.create(dataset: dataset(86), terms_accepted: true)
      app.project_datasets << extra_project_dataset
      app.project_datasets << default_project_dataset
      pdl1 = ProjectDatasetLevel.new(access_level_id: 1, expiry_date: Time.zone.today,
                                     selected: true)
      pdl2 = ProjectDatasetLevel.new(access_level_id: 2, expiry_date: Time.zone.today,
                                     selected: true)
      extra_project_dataset.project_dataset_levels << pdl1
      default_project_dataset.project_dataset_levels << pdl2
      app.save!
    end

    visit project_path(application)

    within "#dataset_#{application.project_datasets.find_by(dataset_id: 83).dataset.id}_row" do
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

    within "#dataset_#{application.project_datasets.find_by(dataset_id: 86).dataset.id}_row" do
      within '#level_1_selected' do
        assert has_no_content?
      end
      within '#level_2_selected' do
        assert find('.glyphicon-ok')
      end
      within '#level_3_selected' do
        assert find('.glyphicon-remove')
      end
      within '#level_1_expiry_date' do
        assert has_no_content?
      end
      within '#level_2_expiry_date' do
        assert has_content?("#{Time.zone.today.strftime('%d/%m/%Y')} (requested)")
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
      find(:css, "#dataset_#{dataset(83).id}_level_1_check_box").set(true)
      find(:css, "#dataset_#{dataset(83).id}_level_1_expiry_datepicker").set('01/01/2022')
    end
    within "#dataset_#{dataset(84).id}_row" do
      find(:css, "#dataset_#{dataset(84).id}_level_2_check_box").set(true)
      find(:css, "#dataset_#{dataset(84).id}_level_2_expiry_datepicker").set('01/01/2022')
      find(:css, "#dataset_#{dataset(84).id}_level_3_check_box").set(true)
      find(:css, "#dataset_#{dataset(84).id}_level_3_expiry_datepicker").set('01/01/2022')
    end

    within "#dataset_#{dataset(86).id}_row" do
      find(:css, "#dataset_#{dataset(86).id}_level_2_check_box").set(true)
      find(:css, "#dataset_#{dataset(86).id}_level_2_expiry_datepicker").set('01/01/2022')
    end

    fill_in('project_cas_application_fields_attributes_reason_justification', with: 'TESTING')
    fill_in('project_cas_application_fields_attributes_extra_datasets_rationale', with: 'TESTING')

    select('Yes', from: 'cas_application_declaration_1')
    select('Yes', from: 'cas_application_declaration_2')
    select('Yes', from: 'cas_application_declaration_3')
    select('Yes', from: 'cas_application_declaration_4')

    click_button('Create Application')

    project_datasets = Project.last.project_datasets

    assert_equal project_datasets.size, 3
    assert_equal project_datasets.find_by(dataset_id: 83).project_dataset_levels.size, 1
    assert_equal project_datasets.find_by(dataset_id: 83).project_dataset_levels.first.access_level_id, 1
    assert project_datasets.find_by(dataset_id: 83).project_dataset_levels.all?(&:selected)
    assert_equal project_datasets.find_by(dataset_id: 84).project_dataset_levels.size, 2
    assert project_datasets.find_by(dataset_id: 84).project_dataset_levels.all?(&:selected)
    assert_equal project_datasets.find_by(dataset_id: 86).project_dataset_levels.size, 1
    assert project_datasets.find_by(dataset_id: 84).project_dataset_levels.all?(&:selected)

    visit edit_project_path(Project.last.id)

    within "#dataset_#{dataset(83).id}_row" do
      find(:css, "#dataset_#{dataset(83).id}_level_1_check_box").set(false)
    end

    click_button('Update Application')

    assert_equal project_datasets.size, 2
    assert_equal project_datasets.pluck(:dataset_id).sort, [84, 86]

    visit edit_project_path(Project.last.id)

    within "#dataset_#{dataset(83).id}_row" do
      find(:css, "#dataset_#{dataset(83).id}_level_2_check_box").set(true)
    end

    click_button('Update Application')

    assert_equal project_datasets.size, 3
    assert_equal project_datasets.find_by(dataset_id: 83).project_dataset_levels.size, 1
    assert_equal project_datasets.find_by(dataset_id: 83).project_dataset_levels.first.access_level_id, 2

    visit edit_project_path(Project.last.id)

    within "#dataset_#{dataset(86).id}_row" do
      find(:css, "#dataset_#{dataset(86).id}_level_2_check_box").set(false)
    end

    click_button('Update Application')

    assert_equal project_datasets.size, 2
    assert_equal project_datasets.pluck(:dataset_id).sort, [83, 84]

    visit edit_project_path(Project.last.id)

    within "#dataset_#{dataset(86).id}_row" do
      find(:css, "#dataset_#{dataset(86).id}_level_2_check_box").set(true)
    end

    click_button('Update Application')

    assert_equal project_datasets.size, 3
    assert_equal project_datasets.find_by(dataset_id: 86).project_dataset_levels.size, 1
    assert_equal project_datasets.find_by(dataset_id: 86).project_dataset_levels.first.access_level_id, 2
  end

  test 'should be able to select default dataset levels using job role checkbox' do
    sign_in users(:no_roles)
    visit new_project_path(project: { project_type_id: project_types(:cas).id })

    find('#ca_group').check

    within '#dataset_85_row' do
      assert has_checked_field?('dataset_85_level_1_check_box')
      assert_equal find('#dataset_85_level_1_expiry_datepicker').value, ''
      assert has_no_checked_field?('dataset_85_level_2_check_box')
      assert has_no_checked_field?('dataset_85_level_3_check_box')
    end

    within '#dataset_86_row' do
      assert has_no_checked_field?('dataset_86_level_1_check_box')
      assert has_checked_field?('dataset_86_level_2_check_box')
      assert_equal find('#dataset_86_level_2_expiry_datepicker').value, ''
      assert has_checked_field?('dataset_86_level_3_check_box')
      assert_equal find('#dataset_86_level_3_expiry_datepicker').value, ''
    end

    within '#dataset_87_row' do
      assert has_no_checked_field?('dataset_87_level_1_check_box')
      assert has_checked_field?('dataset_87_level_2_check_box')
      assert has_no_checked_field?('dataset_87_level_3_check_box')
    end

    fill_in('dataset_85_level_1_expiry_datepicker', with: '01/01/2021')

    assert_equal find('#dataset_85_level_1_expiry_datepicker').value, '01/01/2021'

    find('#d_group').check

    within '#dataset_85_row' do
      assert has_no_checked_field?('dataset_85_level_1_check_box')
      assert_equal find('#dataset_85_level_1_expiry_datepicker').value, ''
      assert has_checked_field?('dataset_85_level_2_check_box')
      assert has_no_checked_field?('dataset_85_level_3_check_box')
    end

    within '#dataset_86_row' do
      assert has_no_checked_field?('dataset_86_level_1_check_box')
      assert has_no_checked_field?('dataset_86_level_2_check_box')
      assert has_no_checked_field?('dataset_86_level_3_check_box')
    end

    within '#dataset_87_row' do
      assert has_no_checked_field?('dataset_87_level_1_check_box')
      assert has_checked_field?('dataset_87_level_2_check_box')
      assert has_no_checked_field?('dataset_87_level_3_check_box')
    end
  end

  test 'some fields should only be viewable to application owner' do
    sign_in users(:no_roles)

    visit new_project_path(project: { project_type_id: project_types(:cas).id })

    assert has_content?('Contract start date')
    assert has_content?('Contract end date')
    assert has_content?('Preferred username')
    assert has_content?('Full physical addresses & postcodes CAS will be accessed from')
    assert has_content?('N3 IP address CAS will be accessed from')
    assert has_content?('I confirm that I completed all the Information Governance training ' \
                        'on as deemed appropriate by my manager. This includes completing ' \
                        'appropriate e-learning modules and other training in the NCRAS ' \
                        'Induction Pack. I agree to update my Information Governance training as ' \
                        'directed by my manager.')

    application = create_cas_project(owner: users(:no_roles))
    application.build_cas_application_fields(address: 'Fake Street', organisation: 'PHE',
                                             declaration: %w[1Yes 2Yes 3Yes 4Yes])
    application.dataset_ids = Dataset.cas.pluck(:id)
    application.save!

    visit project_path(application)

    assert has_content?('Contract start date')
    assert has_content?('Contract end date')
    assert has_content?('Preferred username')
    assert has_content?('Full physical addresses & postcodes CAS will be accessed from')
    assert has_content?('N3 IP address CAS will be accessed from')
    assert has_content?('I confirm that I completed all the Information Governance training ' \
                        'on as deemed appropriate by my manager. This includes completing ' \
                        'appropriate e-learning modules and other training in the NCRAS ' \
                        'Induction Pack. I agree to update my Information Governance training ' \
                        'as directed by my manager.')

    sign_out users(:no_roles)

    sign_in users(:cas_dataset_approver)

    application.transition_to!(workflow_states(:submitted))

    visit project_path(application)

    assert has_no_content?('Contract start date')
    assert has_no_content?('Contract end date')
    assert has_no_content?('Preferred username')
    assert has_no_content?('Full physical addresses & postcodes CAS will be accessed from')
    assert has_no_content?('N3 IP address CAS will be accessed from')
    assert has_no_content?('I confirm that I completed all the Information Governance training ' \
                           'on as deemed appropriate by my manager. This includes completing ' \
                           'appropriate e-learning modules and other training in the NCRAS ' \
                           'Induction Pack. I agree to update my Information Governance training ' \
                           'as directed by my manager.')
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
                                             declaration: %w[1Yes 2Yes 3Yes 4Yes])
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
    sign_in users(:standard_user)

    visit new_project_path(project: { project_type_id: project_types(:cas).id })

    select('Yes', from: 'cas_application_declaration_1')
    select('Yes', from: 'cas_application_declaration_2')
    select('Yes', from: 'cas_application_declaration_3')
    select('Yes', from: 'cas_application_declaration_4')

    click_button('Create Application')

    assert has_button?('Submit', disabled: true)
    assert has_content?('some user details are not complete - please visit the My Account page ' \
                        'to update')
  end

  test 'should show correct user details in the form' do
    sign_in users(:no_roles)

    visit new_project_path(project: { project_type_id: project_types(:cas).id })

    within('#email') do
      assert has_content?('no_roles@phe.gov.uk')
    end

    fill_in('project_cas_application_fields_attributes_reason_justification', with: 'TESTING')
    fill_in('project_cas_application_fields_attributes_extra_datasets_rationale', with: 'TESTING')

    select('Yes', from: 'cas_application_declaration_1')
    select('Yes', from: 'cas_application_declaration_2')
    select('Yes', from: 'cas_application_declaration_3')
    select('Yes', from: 'cas_application_declaration_4')

    find(:css, "#dataset_#{dataset(83).id}_level_1_check_box").set(true)

    click_button('Create Application')

    within('#email') do
      assert has_content?('no_roles@phe.gov.uk')
    end

    application = Project.last
    application.transition_to!(workflow_states(:submitted))

    sign_out users(:no_roles)

    sign_in users(:cas_dataset_approver)

    visit project_path(application)

    within('#email') do
      assert has_content?('no_roles@phe.gov.uk')
    end
  end
end
