require 'test_helper'
# TODO: check destroyingt a Project with ProjectNode does not destroy the node
class ProjectTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  test 'should remove project data items when data source changed' do
    project = build_and_validate_project
    dataset = Dataset.find_by(name: 'Births Gold Standard')
    project.project_datasets << accepted_dataset(dataset)
    project.save!
    assert_equal 2, project.datasets.count
    # Data source for both of the below is Births gold
    project_node_one = create_project_node
    node = dataset.dataset_versions.last.data_items.first
    project_node_two = create_project_node(project: project, node: node)
    # add project data source items
    project.update(project_nodes: [project_node_one, project_node_two])

    assert_equal 2, project.project_nodes.count

    # Change the project data source:
    project.datasets = []
    dataset = Dataset.find_by(name: 'Death Transaction')
    project.project_datasets << accepted_dataset(dataset)
    project.save!

    assert_equal 0, project.project_nodes.count, 'data items should have been removed from project'
  end

  # TODO: move to integration test - now an owner grant that will create automatically
  test 'ensure senior user is a member of a project' do
    # project = build_and_validate_project
    # assert_equal 0, project.project_memberships.count
    # project.update(senior_user: users(:standard_user1))
    # assert_equal 1, project.project_memberships.count
    #
    # # Change the senior_user:
    # project.update(senior_user: users(:standard_user2))
    # assert_equal 2, project.project_memberships.count
  end

  test 'project must have a project data source' do
    project = build_project(project_type: project_types(:project))
    assert project.valid?
    project.project_datasets = []
    refute project.valid?
    assert project.errors[:project_datasets].any?

    project.project_type = project_types(:eoi)
    project.valid?
    refute_includes project.errors.details[:project_datasets], error: :blank

    project = build_project
    assert project.valid?, 'Should be valid - team data source present'
  end

  test 'should validiate acceptance of data source terms when type is project' do
    project = build_project(project_type: project_types(:project), data_source_terms_accepted: false)
    project.valid?
    assert_includes project.errors.details[:data_source_terms_accepted], error: :accepted
  end

  test 'should not validate acceptance of data source terms when type is EOI' do
    project = build_project(project_type: project_types(:eoi), data_source_terms_accepted: false)
    project.valid?
    refute_includes project.errors.details[:data_source_terms_accepted], error: :accepted
  end

  test 'should be validate presence of data dates' do
    project = build_project project_type: project_types(:project),
                            start_data_date: nil,
                            end_data_date:   nil
    project.valid?
    assert_includes project.errors.details[:start_data_date],
                    error: :blank
    assert_includes project.errors.details[:end_data_date],
                    error: :blank

    project.start_data_date = Time.zone.today
    project.valid?
    assert_includes project.errors.details[:end_data_date],
                    error: :blank

    project.end_data_date = Time.zone.tomorrow
    assert project.valid?
  end

  test 'should be invalid if data end date is before start date' do
    project = build_project project_type:    project_types(:project),
                            start_data_date: Time.zone.tomorrow,
                            end_data_date:   Time.zone.today

    project.valid?
    assert_includes project.errors.details[:end_data_date], error: 'must be after start date'
  end

  test 'should not validate data dates when type is EOI' do
    project = build_project project_type:    project_types(:eoi),
                            start_data_date: Time.zone.tomorrow,
                            end_data_date:   Time.zone.today

    project.valid?
    refute_includes project.errors.details[:end_data_date], error: 'must be after start date'
  end

  test 'submitted?' do
    project = projects(:one)
    assert project.submitted?

    project.stubs(current_state: workflow_states(:draft))
    refute project.submitted?
  end

  # TODO: Deprecated.
  test 'friendly project status message - pending' do
    skip

    project = build_project(z_project_status: z_project_statuses(:pending))
    assert_equal project.friendly_status_message, 'Pending Approval'
  end

  # TODO: Deprecated.
  test 'friendly project status message - new' do
    skip

    project = build_project(z_project_status: z_project_statuses(:new))
    assert_equal project.friendly_status_message, 'New Project'
  end

  # TODO: Deprecated.
  test 'friendly project status message - other' do
    skip

    project = build_project(z_project_status: z_project_statuses(:approved))
    assert_equal project.friendly_status_message, 'Approved'
  end

  test 'an annual project with 30 days remaining is notified' do
    p = create_project(name: '30 day test', end_data_date: Time.zone.now + 30.days,
                       frequency: 'Annually')
    # Team for this project now has two delegate users
    assert_difference('Notification.count', 2) do
      Project.check_for_expiring_projects
    end
    assert_equal Notification.last.title, '30 day test - Will expire in 30 days'
    assert_equal Notification.last.body, ( CONTENT_TEMPLATES['email_project_day_expiry']['body'] %
                                           { project: p.name,
                                             number_of_days: (p.end_data_date - Time.zone.today).to_i,
                                             expiry_date: p.end_data_date,
                                             data_set: p.datasets.map(&:name).join(' | ') })
  end

  test 'a non annual project with 14 days remaining is notified' do
    pj = create_project(name: '14 day test', end_data_date: Time.zone.now + 14.days, frequency: 'Monthly')
    assert_difference('Notification.count', 2) do
      Project.check_for_expiring_projects
    end
    assert_equal Notification.last.title, '14 day test - Will expire in 14 days'
    days = (pj.end_data_date - Time.zone.today).to_i
    assert_equal Notification.last.body, ( CONTENT_TEMPLATES['email_project_day_expiry']['body'] %
                                           { project: pj.name,
                                             number_of_days: days,
                                             expiry_date: pj.end_data_date,
                                             data_set: pj.datasets.map(&:name).join('|') })
  end

  test 'a non annual project with 1 days remaining is notified' do
    p = create_project(name: '1 day test', end_data_date: Time.zone.now + 1.day, frequency: 'Monthly')
    assert_difference('Notification.count', 2) do
      Project.check_for_expiring_projects
    end
    assert_equal Notification.last.title, '1 day test - Will expire in 1 days'
    assert_equal Notification.last.body, ( CONTENT_TEMPLATES['email_project_day_expiry']['body'] %
                                           { project: p.name,
                                             number_of_days: (p.end_data_date - Time.zone.today).to_i,
                                             expiry_date: p.end_data_date,
                                             data_set: p.datasets.map(&:name).join('|') })
  end

  test 'non expiring projects are not notified' do
    create_project(name: '31 day test', end_data_date: Time.zone.now + 31.days, frequency: 'Annually')
    create_project(name: '15 day test', end_data_date: Time.zone.now + 15.days, frequency: 'Monthly')
    create_project(name: '2 day test', end_data_date: Time.zone.now + 2.days, frequency: 'Monthly')

    assert_difference('Notification.count', 0) do
      Project.check_for_expiring_projects
    end
  end

  test 'a project that has passed the end data date is set to expired' do
    create_project(name: 'Expired project test', end_data_date: Time.zone.now - 2.days, frequency: 'Annually')
    assert_difference('Project.not_in_use.count', 1) do
      assert_difference('Notification.count', 2) do
        Project.check_and_set_expired_projects
      end
    end
    assert_equal 'Expired project test - Expired', Notification.last.title
    assert_equal 'EXPIRED', Project.last.current_state.id
  end

  test 'cloning a project should clone multi fields if present' do
    original_project = create_project(name: 'clone me', end_data_date: Time.zone.now - 31.days)
    original_project.update_attribute(:end_uses, EndUse.all)
    classifications = [classifications(:one), classifications(:two)]
    original_project.update_attribute(:classifications, classifications)
    original_project.update_attribute(:outputs, [outputs(:one)])

    ignored_project_keys = %w[id name]
    existing_project_attrs = original_project.attributes.except(*ignored_project_keys).dup
    existing_project_attrs['clone_of'] = original_project.id
    cloned_project = Project.new(existing_project_attrs)
    cloned_project.name = 'Cloned Project'
    cloned_project.owner = original_project.owner
    cloned_project.save!

    refute cloned_project.end_uses == original_project.end_uses
    refute cloned_project.classifications == original_project.classifications
    refute cloned_project.outputs == original_project.outputs

    cloned_project.send(:clone_project_sub_details)
    # original items remain
    assert original_project.end_uses.count.positive?
    assert original_project.classifications.count.positive?
    assert original_project.outputs.count.positive?
    assert cloned_project.end_uses, original_project.end_uses
    assert cloned_project.classifications, original_project.classifications
    assert cloned_project.outputs, original_project.outputs
  end

  test 'should only be assignable to application managers' do
    team    = teams(:team_one)
    project = build_project(team: team)

    application_manager     = users(:application_manager_one)
    not_application_manager = users(:standard_user)

    project.assigned_user = not_application_manager
    project.valid?
    assert_includes project.errors.details[:assigned_user], error: :invalid

    application_manager.stubs(flagged_as_active?: false)
    project.assigned_user = application_manager
    project.valid?
    assert_includes project.errors.details[:assigned_user], error: :invalid

    application_manager.unstub(:flagged_as_active?)
    project.valid?
    refute_includes project.errors.details[:assigned_user], error: :invalid
  end

  test 'assigned scope' do
    project  = projects(:one)
    user_one = users(:application_manager_one)
    user_two = users(:application_manager_two)

    refute_includes Project.assigned, project
    refute_includes Project.assigned(check_temporal: true), project

    project.update!(assigned_user: user_one)
    assert_includes Project.assigned, project
    assert_includes Project.assigned(check_temporal: true), project

    project.update!(assigned_user: nil)
    project.current_project_state.assign_to!(user: user_one, assigning_user: user_two)
    refute_includes Project.assigned, project
    assert_includes Project.assigned(check_temporal: true), project
  end

  test 'unassigned scope' do
    project  = projects(:one)
    user_one = users(:application_manager_one)
    user_two = users(:application_manager_two)

    assert_includes Project.unassigned, project
    assert_includes Project.unassigned(check_temporal: true), project

    project.update!(assigned_user: user_one)
    refute_includes Project.unassigned, project
    refute_includes Project.unassigned(check_temporal: true), project

    project.update!(assigned_user: nil)
    project.current_project_state.assign_to!(user: user_one, assigning_user: user_two)
    assert_includes Project.unassigned, project
    refute_includes Project.unassigned(check_temporal: true), project
  end

  test 'assigned_to scope' do
    project  = projects(:one)
    user_one = users(:application_manager_one)
    user_two = users(:application_manager_two)

    refute_includes Project.assigned_to(user_one), project
    refute_includes Project.assigned_to(user_one, check_temporal: true), project

    project.update!(assigned_user: user_one)
    assert_includes Project.assigned_to(user_one), project
    assert_includes Project.assigned_to(user_one, check_temporal: true), project

    project.update!(assigned_user: user_two)
    project.current_project_state.assign_to!(user: user_one, assigning_user: user_two)
    refute_includes Project.assigned_to(user_one), project
    assert_includes Project.assigned_to(user_one, check_temporal: true), project
  end

  test 'of_type_project scope' do
    project = projects(:one)
    dummy   = projects(:dummy_project)
    eoi     = build_project(project_type: project_types(:eoi), name: 'Test EOI')

    eoi.save(validate: false)

    assert_includes Project.of_type_project, project
    refute_includes Project.of_type_project, dummy
    refute_includes Project.of_type_project, eoi
  end

  test 'should require project_purpose if EOI' do
    eoi = build_project(project_type: project_types(:eoi), name: 'Test EOI')

    eoi.valid?
    assert_includes eoi.errors.details[:project_purpose], error: :blank

    eoi.project_purpose = 'testing'
    eoi.valid?
    refute_includes eoi.errors.details[:project_purpose], error: :blank
  end

  test 'should not require project_purpose if Project' do
    project = projects(:one)

    project.project_purpose = nil
    project.valid?
    refute_includes project.errors.details[:project_purpose], error: :blank
  end

  test 'should validate uniqueness of name' do
    project = projects(:one)
    other   = project.team.projects.build(
      name: project.name,
      project_type: project.project_type
    )

    other.valid?
    assert_includes other.errors.details[:name], error: :taken, value: project.name

    other.name = 'Something Else'
    other.valid?
    refute_includes other.errors.details[:name], error: :taken, value: 'Something Else'

    other.assign_attributes(
      name: project.name,
      project_type: project_types(:eoi)
    )
    other.valid?
    refute_includes other.errors.details[:name], error: :taken, value: project.name

    other.assign_attributes(
      team: teams(:team_two),
      name: project.name,
      project_type: project.project_type
    )
    other.valid?
    refute_includes other.errors.details[:name], error: :taken, value: project.name
  end

  # Postgres blank value test
  test 'Can save Application with blank fields' do
    application = Project.new(project_type: project_types(:application),
                              name: 'Application Test',
                              team: teams(:team_one),
                              owner: users(:application_manager_three),
                              sponsor_country_id: "",
                              funder_country_id: "",
                              data_processor_country_id: "",
                              first_contact_date: Date.current - 1.month)

    # They'll be many more validations to add...
    assert application.valid?
    assert_difference('Project.count', 1) do
      application.save!
    end
  end

  test 'Project with item groups returns items' do
    team = create_team(name: 'ITEM GROUP TEAM')
    dataset = Dataset.create!(name: 'ITEM GROUP TEST', dataset_type: dataset_type(:table_spec),
                              team: team)
    dataset_version = dataset.dataset_versions.build(semver_version: '1.0')
    version_entity = Nodes::Entity.new(name: dataset.name, dataset_version: dataset_version,
                                       min_occurs: 1, max_occurs: 1)
    default_options = { min_occurs: 0, max_occurs: 1, dataset_version: dataset_version }
    item_group = Nodes::DataItemGroup.new(default_options.merge(name: 'item_group_node'))
    item_one = Nodes::DataItem.new(default_options.merge(name: 'Item one'))
    item_two = Nodes::DataItem.new(default_options.merge(name: 'Item two'))
    item_three = Nodes::DataItem.new(default_options.merge(name: 'Item three'))
    item_group.child_nodes << item_one
    item_group.child_nodes << item_two
    version_entity.child_nodes << item_group
    version_entity.child_nodes << item_three
    version_entity.save!

    project = Project.new(name: 'TEST', project_type: project_types(:project))
    project.nodes << item_group
    project.nodes << item_two
    project.datasets << dataset
    project.save(validate: false)

    assert_equal 2, project.nodes.count
    assert_equal 3, project.all_data_items.count
  end

  test 'CAS application does not require team' do
    application = Project.new(project_type: ProjectType.find_by(name: 'CAS')).tap(&:valid?)
    refute_includes(application.errors.keys, :project)
  end

  test 'MBIS application requires team' do
    application = Project.new(project_type: ProjectType.find_by(name: 'Project')).tap(&:valid?)
    assert_includes(application.errors.keys, :project)
  end

  test 'CAS application does not require name' do
    application = Project.new(project_type: ProjectType.find_by(name: 'EOI')).tap(&:valid?)
    assert_includes(application.errors.keys, :project)

    application = Project.new(project_type: ProjectType.find_by(name: 'CAS')).tap(&:valid?)
    refute_includes(application.errors.keys, :project)
  end

  test 'cas_dataset_approval scope should only return projects that user is allowed to approve' do
    user = users(:standard_user2)
    dataset = Dataset.find_by(name: 'Extra CAS Dataset One')
    # grant user approver role for our dataset
    Grant.create(roleable: DatasetRole.fetch(:approver), dataset: dataset, user: user)

    cas_project = create_cas_project(owner: users(:standard_user1)).tap(&:valid?)

    project_dataset = ProjectDataset.new(dataset: dataset, terms_accepted: true)
    cas_project.project_datasets << project_dataset
    pdl = ProjectDatasetLevel.new(access_level_id: 1, expiry_date: Time.zone.today + 1.week,
                                  approved: nil)
    project_dataset.project_dataset_levels << pdl

    # Should not be returned while at DRAFT state
    assert_equal 0, Project.cas_dataset_approval(user).count

    cas_project.transition_to!(workflow_states(:submitted))

    assert_equal 1, Project.cas_dataset_approval(user).count

    pdl.approved = true
    pdl.save!(validate: false)

    # Test the use of the scope with and without approved = nil argument
    assert_equal 0, Project.cas_dataset_approval(user, [nil]).count
    assert_equal 1, Project.cas_dataset_approval(user).count

    new_project = create_cas_project(owner: users(:standard_user1)).tap(&:valid?)
    new_project_dataset = ProjectDataset.new(dataset: Dataset.find_by(name: 'SACT'),
                                             terms_accepted: true)
    new_project.project_datasets << new_project_dataset
    pdl = ProjectDatasetLevel.new(access_level_id: 1, expiry_date: Time.zone.today + 1.week,
                                  approved: nil)
    new_project_dataset.project_dataset_levels << pdl

    new_project.transition_to!(workflow_states(:submitted))

    assert_equal 0, Project.cas_dataset_approval(user, [nil]).count
  end

  test 'should notify cas_manager on new project creation' do
    notifications = Notification.where(title: 'New CAS Application Created')

    assert_difference 'notifications.count', 2 do
      create_cas_project(project_purpose: 'notify new project',
                     owner: users(:no_roles))
    end

    project = Project.where(project_purpose: 'notify new project').last

    assert_equal notifications.last.body, "CAS application #{project.id} has been created.\n\n"

    assert_no_difference 'notifications.count' do
      project.save!
      project.update(project_purpose: 'test updating does not trigger')
    end
  end

  test 'do not email non phe emails on odr transitions' do
    project = build_project(project_type: ProjectType.find_by(name: 'Application'))
    project.save!(validate: false)
    project.reload

    assert_difference 'Notification.count', 3 do
      assert_emails 3 do
        project.odr_approval_needed_notification
        project.odr_rejected_notification
        project.odr_approved_notification
      end
    end

    # rebuild project - changing an owner sets the previous owner as a contributor
    project = build_project(project_type: ProjectType.find_by(name: 'Application'))
    project.owner = users(:non_phe_user)
    project.save!(validate: false)
    project.reload

    assert_difference 'Notification.count', 3 do
      assert_no_emails do
        project.odr_approval_needed_notification
        project.odr_rejected_notification
        project.odr_approved_notification
      end
    end
  end

  # this is the ODR system role
  test 'ODR should be emailed when MBIS application is submitted' do
    project = build_project(project_type: project_types(:project))
    project.save!(validate: false)
    project.reload

    # 2 ODR users in fixtures
    # 1 owner of application
    assert_difference 'Notification.count', 1 do
      assert_emails 3 do
        project.odr_approval_needed_notification
      end
    end
  end

  test 'fetches an application date' do
    project = Project.new(
      project_type: project_types(:dummy),
      name: 'Application Date test'
    )

    assert_nil project[:application_date]

    timestamp = Time.zone.now
    travel_to(timestamp) do
      assert_equal timestamp.to_s, project.application_date.to_s
    end

    travel_to(1.day.ago) { project.save!(validate: false) }
    assert_equal project.created_at, project.application_date

    timestamp = 2.days.ago
    project.application_date = timestamp
    assert_equal timestamp, project.application_date
  end

  test 'destroy_project_datasets_without_any_levels after_save callback' do
    project = create_cas_project(owner: users(:standard_user2))
    project_dataset = ProjectDataset.new(dataset: dataset(83), terms_accepted: true)
    project.project_datasets << project_dataset
    pdl1 = ProjectDatasetLevel.new(access_level_id: 1, expiry_date: Time.zone.today, selected: true)
    pdl2 = ProjectDatasetLevel.new(access_level_id: 2, expiry_date: Time.zone.today, selected: true)
    project_dataset.project_dataset_levels << pdl1
    project_dataset.project_dataset_levels << pdl2
    project.save!

    pdl2.destroy
    project.save!
    project.reload

    assert_equal project.project_datasets.size, 1

    pdl1.destroy
    project.save!
    project.reload

    assert_equal project.project_datasets.size, 0
  end

  test 'returns an ODR application_log based of financialy year and id if application_log is nil' do
    %i[eoi application].each do |type|
      assert_application_log('ODR_2021_', name: 'application log test 1',
                                          project_type: project_types(type),
                                          first_contact_date: Date.parse('2021/03/31'))
      assert_application_log('ODR_2122_', name: 'application log test 2',
                                          project_type: project_types(type),
                                          first_contact_date: Date.parse('2021/04/01'))
    end
  end

  test 'should not create an application log for an MBIS Application' do
    project = build_project(project_type: project_types(:project))
    project.save!
    assert_nil project.application_log
  end

  test 'should not create an application log for a CAS Application' do
    project = build_project(project_type: project_types(:cas))
    project.save!
    assert_nil project.application_log
  end

  test 'should return nil for application_log if no first_contact_date' do
    project = build_project(project_type: project_types(:project))
    project.save!
    assert_nil project.application_log
  end

  test 'next amendment reference for legacy ODR application' do
    project = build_project(project_type: project_types(:application),
                            first_contact_date: Date.parse('2021/04/01'),
                            application_log: 'ODR_legacy_id').tap(&:save!)
    assert_equal 'ODR_legacy_id', project.application_log
    assert_equal 'ODR_legacy_id/A1', project.next_amendment_reference
  end

  test 'first_contact_date not required for pdf import' do
    project = Project.new(project_type: project_types(:application)).tap(&:valid?)
    assert_includes project.errors.messages.keys, :first_contact_date

    team = teams(:team_one)
    project = team.projects.build(project_type: project_types(:application))
    facade = PdfApplicationFacade.new(project)
    refute_includes facade.errors.messages.keys, :first_contact_date
  end

  private

  def assert_application_log(expected, options = {})
    project = application_log_project(options)
    project.save!
    assert_equal "#{expected}#{project.id}", project.reload.application_log
  end

  def application_log_project(options = {})
    default_options = {
      project_type: project_types(:eoi),
      name: 'test',
      project_purpose: 'log',
      team: teams(:team_one),
      owner: users(:application_manager_three)
    }
    project = Project.new(default_options.merge(options))

    project
  end
end
