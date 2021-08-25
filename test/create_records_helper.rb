module CreateRecordsHelper
  #### Users ####
  def create_user(options = {})
    build_user(options).tap(&:save!)
  end

  def build_and_validate_user(options = {})
    build_user(options).tap(&:valid?)
  end

  def build_user(options = {})
    default_options = {
      email: 'test@phe.gov.uk',
      password: 'Password1*',
      first_name: 'first_name_test',
      last_name: 'last_name_test',
      username: 'username',
      telephone: '01223',
      location: 'Cambridge',
      notes: 'This is a test user',
      directorate_id: Directorate.where(name: 'Directorate 1').first.id,
      division_id: Division.where(name: 'Division 1 from directorate 1').first.id,
      z_user_status_id: ZUserStatus.where(name: 'Active').first.id
    }

    User.new(default_options.merge(options))
  end

  #### Teams ####
  def create_team(options = {})
    build_team(options).tap(&:save!)
  end

  def build_and_validate_team(options = {})
    build_team(options).tap(&:valid?)
  end

  def build_team(options = {})
    default_options = {
      organisation: organisations(:test_organisation_one),
      name: 'NCRS',
      location: 'Cambridge',
      directorate_id: 1,
      division_id: 1,
      telephone: '01223',
      notes: 'Test Team',
      z_team_status_id: 1,
      # TODO:
      # delegate_users: [users(:delegate_user1)]
    }
    Team.new(default_options.merge(options))
  end

  #### Projects ####
  def create_project(options = {})
    build_project(options).tap(&:save!)
  end

  def create_cas_project(options = {})
    default_options = {
      project_type: project_types(:cas),
      name: 'NCRS',
      description: 'Example CAS Project',
      owner: users(:standard_user2),
      cas_application_fields: CasApplicationFields.new(declaration: %w[1Yes 2Yes 3Yes 4Yes])
    }
    cas = Project.new(default_options.merge(options))
    cas.save!
    User.find(cas.owner.id).update(
      job_title: 'Tester',
      telephone: '01234 5678910',
      line_manager_name: 'Line Manager',
      line_manager_email: 'linemanager@test.co.uk',
      line_manager_telephone: '10987 654321',
      employment: 'Contract',
      contract_start_date: '01/01/2021',
      contract_end_date: '30/06/2021'
    )
    cas.reload.current_state
    cas
  end

  def build_and_validate_project(options = {})
    build_project(options).tap(&:valid?)
  end

  def build_project(options = {})
    default_options = {
      project_type: project_types(:project),
      name: 'NCRS',
      description: 'Example Project',
      team: teams(:team_one),
      start_data_date: '01/01/2017',
      end_data_date: '31/12/2017',
      first_contact_date: '31/12/2016',
      data_to_contact_others: true,
      data_to_contact_others_desc: 'do something',
      classifications: [classifications(:one), classifications(:two)],
      owner: users(:standard_user2)
    }
    project = Project.new(default_options.merge(options), &:initialize_workflow)
    dataset = Dataset.find_by(name: 'Death Transaction')
    project.project_datasets << ProjectDataset.new(dataset: dataset,
                                                   terms_accepted: true)
    project
  end

  #### ProjectNode ####
  def create_project_node(options = {})
    build_project_node(options).tap(&:save!)
  end

  def build_and_validate_project_data_source_item(options = {})
    build_project_node(options).tap(&:valid?)
  end

  def build_project_node(options = {})
    node = Dataset.find_by(name: 'Births Gold Standard').dataset_versions.
           last.data_items.find_by(name: 'DOB')
    default_options = {
      project: projects(:one),
      node: node
    }
    ProjectNode.new(default_options.merge(options))
  end

  ### Notifications ###
  def create_notification(options = {})
    build_notification(options).tap(&:save!)
  end

  def build_and_validate_notification(options = {})
    build_notification(options).tap(&:valid?)
  end

  def build_notification(options = {})
    default_options = {
      title: 'Simple Notifications',
      body: 'Simple Notifications body'
    }

    Notification.new(default_options.merge(options))
  end

  def select_and_accept_new_dataset(dataset_name)
    find_new('select') do
      new_checkbox = find_new(:checkbox) do
        click_on 'Add Dataset'
      end
      find(:option, dataset_name).select_option
      new_checkbox.check
    end
  end

  def new_dataset
    find_new('select') do
      click_on 'Add Dataset'
    end
  end

  def accepted_dataset(dataset)
    ProjectDataset.new(dataset: dataset, terms_accepted: true)
  end

  def create_amendment(project, **attributes)
    file    = attributes.delete(attributes[:file]) || 'odr_amendment_request_form-1.0.pdf'
    fixture = file_fixture(file)
    upload  = ActionDispatch::Http::UploadedFile.new(
      tempfile: File.new(fixture, 'rb'),
      filename: fixture.basename.to_s,
      type:     'application/pdf'
    )

    attributes.reverse_merge!(
      requested_at: 1.day.ago,
      amendment_approved_date: Time.zone.today,
      upload: upload
    )

    project.project_amendments.create!(attributes)
  end

  def create_dpia(project, **attributes)
    file    = attributes.delete(attributes[:file]) || 'dpia.txt'
    fixture = file_fixture(file)
    upload  = ActionDispatch::Http::UploadedFile.new(
      tempfile: File.new(fixture, 'rb'),
      filename: fixture.basename.to_s,
      type:     'text/plain'
    )

    attributes.reverse_merge!(
      referent: project,
      ig_toolkit_version: '2019/20',
      ig_score: 100,
      ig_assessment_status: lookups_ig_assessment_statuses(:standards_met),
      review_meeting_date: 1.week.ago,
      upload: upload
    )

    project.global_dpias.create!(attributes)
  end

  def create_contract(project, **attributes)
    file    = attributes.delete(attributes[:file]) || 'contract.txt'
    fixture = file_fixture(file)
    upload  = ActionDispatch::Http::UploadedFile.new(
      tempfile: File.new(fixture, 'rb'),
      filename: fixture.basename.to_s,
      type:     'text/plain'
    )

    attributes.reverse_merge!(
      referent:               project,
      contract_start_date:    Time.zone.today + 1.week,
      contract_end_date:      Time.zone.today + 1.year,
      contract_sent_date:     Time.zone.today - 2.weeks,
      contract_returned_date: Time.zone.today - 1.week,
      contract_executed_date: Time.zone.today,
      contract_version:       'test-0.0.1',
      upload:                 upload
    )

    project.global_contracts.create!(attributes)
  end

  def create_release(project, **attributes)
    attributes.reverse_merge!(
      referent:               project,
      invoice_requested_date: 1.week.ago,
      invoice_sent_date:      1.day.ago,
      phe_invoice_number:     'PHE-1234',
      po_number:              'PO-2345',
      cprd_reference:         'CPRD-3456',
      actual_cost:            1000.00,
      vat_reg:                'NA',
      income_received:        'N',
      drr_no:                 'DRR-4567',
      cost_recovery_applied:  'N'
    )

    project.global_releases.create!(attributes)
  end
end
