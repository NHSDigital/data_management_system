namespace :cas do
  # run using - e.g - bin/rake cas:create EMAIL=cda2@phe.gov.uk,caa@phe.gov.uk
  desc 'build all scenarios for testing'
  task create: %i[scenario_one scenario_two scenario_three scenario_four scenario_five]

  desc 'create 6 cas default and 2 cas extra levels that are ready for renewal'
  task scenario_one: :environment do
    email_addresses = ENV['EMAIL'].split(',')
    email_addresses.each do |email|
      owner = User.find_by(email: email)
      project = create_cas_project(owner: owner, name: "Renewal test - owner #{owner.first_name}",
                                   description: "renewal test - owner #{owner.first_name}")
      default_pd_one = ProjectDataset.create(dataset: Dataset.cas_defaults.first,
                                             terms_accepted: true, project_id: project.id)
      default_pd_two = ProjectDataset.create(dataset: Dataset.cas_defaults.last,
                                             terms_accepted: true, project_id: project.id)
      ProjectDatasetLevel.create(access_level_id: 1, selected: true,
                                 project_dataset_id: default_pd_one.id,
                                 expiry_date: Time.zone.today + 1.month)
      ProjectDatasetLevel.create(access_level_id: 2, selected: true,
                                 project_dataset_id: default_pd_one.id)
      ProjectDatasetLevel.create(access_level_id: 3, selected: true,
                                 project_dataset_id: default_pd_one.id)
      ProjectDatasetLevel.create(access_level_id: 1, selected: true,
                                 project_dataset_id: default_pd_two.id,
                                 expiry_date: Time.zone.today + 1.month)
      ProjectDatasetLevel.create(access_level_id: 2, selected: true,
                                 project_dataset_id: default_pd_two.id)
      ProjectDatasetLevel.create(access_level_id: 3, selected: true,
                                 project_dataset_id: default_pd_two.id)

      extra_pd = ProjectDataset.create(dataset: Dataset.cas_extras.first, terms_accepted: true,
                                       project_id: project.id)
      ProjectDatasetLevel.create(access_level_id: 1, selected: true,
                                 project_dataset_id: extra_pd.id,
                                 expiry_date: Time.zone.today + 1.month)
      ProjectDatasetLevel.create(access_level_id: 2, selected: true,
                                 project_dataset_id: extra_pd.id,
                                 expiry_date: Time.zone.today + 1.month)

      project.reload_current_state
      project.transition_to!(Workflow::State.find('SUBMITTED'))

      default_pd_one.project_dataset_levels.update_all(status: 2, decided_at: Time.zone.now)
      default_pd_two.project_dataset_levels.update_all(status: 2, decided_at: Time.zone.now)
      extra_pd.project_dataset_levels.update_all(status: 2, decided_at: Time.zone.now)

      # auto transition takes it to ACCESS_GRANTED
      project.transition_to!(Workflow::State.find('ACCESS_APPROVER_APPROVED'))

      default_pd_one.project_dataset_levels.update_all(status: 4,
                                                       expiry_date: Time.zone.today + 1.month)
      default_pd_two.project_dataset_levels.update_all(status: 4,
                                                       expiry_date: Time.zone.today + 1.month)
      extra_pd.project_dataset_levels.update_all(status: 4,
                                                 expiry_date: Time.zone.today + 1.month)

      puts "#{project.id} created"
    end
  end

  desc 'create 2 cas default and 2 cas extra levels that are ready for reapply'
  task scenario_two: :environment do
    email_addresses = ENV['EMAIL'].split(',')
    email_addresses.each do |email|
      owner = User.find_by(email: email)
      project = create_cas_project(owner: owner, name: "Reapply test - owner #{owner.first_name}",
                                   description: "reapply test - owner #{owner.first_name}")
      default_pd = ProjectDataset.create(dataset: Dataset.cas_defaults.first, terms_accepted: true,
                                         project_id: project.id)
      default_l1_pdl = ProjectDatasetLevel.create(access_level_id: 1, selected: true,
                                                  project_dataset_id: default_pd.id,
                                                  expiry_date: Time.zone.today + 6.months)
      default_l2_pdl = ProjectDatasetLevel.create(access_level_id: 2, selected: true,
                                                  project_dataset_id: default_pd.id)
      extra_pd = ProjectDataset.create(dataset: Dataset.cas_extras.first, terms_accepted: true,
                                       project_id: project.id)
      ProjectDatasetLevel.create(access_level_id: 1, selected: true,
                                 project_dataset_id: extra_pd.id,
                                 expiry_date: Time.zone.today + 6.months)
      ProjectDatasetLevel.create(access_level_id: 2, selected: true,
                                 project_dataset_id: extra_pd.id,
                                 expiry_date: Time.zone.today + 6.months)
      # added to make more realistic as you wouldn't get to this stage without at least 1 approval
      approved_pd = ProjectDataset.create(dataset: Dataset.cas_defaults.last, terms_accepted: true,
                                          project_id: project.id)
      approved_pdl = ProjectDatasetLevel.create(access_level_id: 2, selected: true,
                                                project_dataset_id: approved_pd.id)

      project.reload_current_state
      project.transition_to!(Workflow::State.find('SUBMITTED'))

      default_l1_pdl.update(status: 3, decided_at: Time.zone.now)
      default_l2_pdl.update(status: 3, decided_at: Time.zone.now)
      extra_pd.project_dataset_levels.update_all(status: 3, decided_at: Time.zone.now)
      approved_pdl.update(status: 2, decided_at: Time.zone.now)

      # auto transition takes it to ACCESS_GRANTED
      project.transition_to!(Workflow::State.find('ACCESS_APPROVER_APPROVED'))

      puts "#{project.id} created"
    end
  end
end

desc 'create 10 level 2 cas defaults ready for bulk approval and some level 1s ready for manual'
task scenario_three: :environment do
  email_addresses = ENV['EMAIL'].split(',')
  email_addresses.each do |email|
    owner = User.find_by(email: email)
    project = create_cas_project(owner: owner, name: "Approval test - owner #{owner.first_name}",
                                 description: "approval test - owner #{owner.first_name}")

    Dataset.cas_defaults.limit(10).each_with_index do |dataset, i|
      pd = ProjectDataset.create(dataset: dataset, terms_accepted: true, project_id: project.id)
      # create level 2 levels for all default datasets
      ProjectDatasetLevel.create(access_level_id: 2, selected: true, project_dataset_id: pd.id)
      next unless [0, 1].include? i

      # create level 1 levels for 2 default datasets
      ProjectDatasetLevel.create(access_level_id: 1, selected: true,
                                 expiry_date: Time.zone.today + 6.months, project_dataset_id: pd.id)
    end

    project.reload_current_state
    project.transition_to!(Workflow::State.find('SUBMITTED'))

    puts "#{project.id} created"
  end
end

desc 'create project that is ready for rejection when at Submitted'
task scenario_four: :environment do
  email_addresses = ENV['EMAIL'].split(',')
  email_addresses.each do |email|
    owner = User.find_by(email: email)
    project = create_cas_project(owner: owner,
                                 description: "account rejection test - owner #{owner.first_name}",
                                 name: "Account rejection test - owner #{owner.first_name}")
    default_pd = ProjectDataset.create(dataset: Dataset.cas_defaults.first, terms_accepted: true,
                                       project_id: project.id)
    ProjectDatasetLevel.create(access_level_id: 1, selected: true,
                               project_dataset_id: default_pd.id,
                               expiry_date: Time.zone.today + 1.month)
    ProjectDatasetLevel.create(access_level_id: 2, selected: true,
                               project_dataset_id: default_pd.id)
    extra_pd = ProjectDataset.create(dataset: Dataset.cas_extras.first, terms_accepted: true,
                                     project_id: project.id)
    ProjectDatasetLevel.create(access_level_id: 1, selected: true, project_dataset_id: extra_pd.id,
                               expiry_date: Time.zone.today + 1.month)
    ProjectDatasetLevel.create(access_level_id: 2, selected: true, project_dataset_id: extra_pd.id,
                               expiry_date: Time.zone.today + 1.month)

    project.reload_current_state
    project.transition_to!(Workflow::State.find('SUBMITTED'))

    puts "#{project.id} created"
  end
end

desc 'create project that is ready for account closure testing'
task scenario_five: :environment do
  email_addresses = ENV['EMAIL'].split(',')
  email_addresses.each do |email|
    owner = User.find_by(email: email)
    project = create_cas_project(owner: owner,
                                 name: "Account closure test - owner #{owner.first_name}",
                                 description: "account closure test - owner #{owner.first_name}")
    default_pd = ProjectDataset.create(dataset: Dataset.cas_defaults.first, terms_accepted: true,
                                       project_id: project.id)
    default_l1_pdl = ProjectDatasetLevel.create(access_level_id: 1, selected: true,
                                                project_dataset_id: default_pd.id,
                                                expiry_date: Time.zone.today + 1.month)
    default_l2_pdl = ProjectDatasetLevel.create(access_level_id: 2, selected: true,
                                                project_dataset_id: default_pd.id)
    extra_pd = ProjectDataset.create(dataset: Dataset.cas_extras.first, terms_accepted: true,
                                     project_id: project.id)
    ProjectDatasetLevel.create(access_level_id: 1, selected: true, project_dataset_id: extra_pd.id,
                               expiry_date: Time.zone.today + 1.month)
    ProjectDatasetLevel.create(access_level_id: 2, selected: true, project_dataset_id: extra_pd.id,
                               expiry_date: Time.zone.today + 1.month)

    project.reload_current_state
    project.transition_to!(Workflow::State.find('SUBMITTED'))

    default_l1_pdl.update(status: 2, decided_at: Time.zone.now)
    default_l2_pdl.update(status: 2, decided_at: Time.zone.now,
                          expiry_date: Time.zone.today + 1.month)
    extra_pd.project_dataset_levels.update_all(status: 2, decided_at: Time.zone.now)

    # auto transition takes it to ACCESS_GRANTED
    project.transition_to!(Workflow::State.find('ACCESS_APPROVER_APPROVED'))

    puts "#{project.id} created"
  end
end

def create_cas_project(options = {})
  default_options = {
    project_type: ProjectType.find_by(name: 'CAS'),
    name: 'NCRS',
    description: 'Example CAS Project',
    cas_application_fields: CasApplicationFields.new(declaration: %w[1Yes 2Yes 3Yes 4Yes])
  }
  Project.create(default_options.merge(options))
end
