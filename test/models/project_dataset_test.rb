require 'test_helper'

class ProjectDatasetTest < ActiveSupport::TestCase
  test 'Only unique datasets allowed' do
    project = build_project
    dataset = Dataset.find_by(name: 'Deaths Gold Standard')
    project_dataset = ProjectDataset.new(dataset: dataset)
    project.project_datasets << project_dataset
    project.project_datasets << project_dataset
    refute project.valid?
  end

  test 'dataset_approval scope should only return to user with correct grant' do
    project = Project.create(project_type: project_types(:cas), owner: users(:standard_user2))
    project_dataset = ProjectDataset.new(dataset: Dataset.find_by(name: 'Extra CAS Dataset One'))
    project.project_datasets << project_dataset

    assert_equal 0, ProjectDataset.dataset_approval(users(:standard_user2)).count

    assert_equal 1, ProjectDataset.dataset_approval(users(:cas_dataset_approver)).count

    grant = Grant.where(user_id: users(:cas_dataset_approver).id).first
    grant.dataset_id = 84
    grant.save!

    assert_equal 0, ProjectDataset.dataset_approval(users(:cas_dataset_approver)).count
  end

  test 'dataset_approval scope should return all datasets for that user by default' do
    project = Project.create(project_type: project_types(:cas), owner: users(:standard_user2))
    project_dataset = ProjectDataset.new(dataset: Dataset.find_by(name: 'Extra CAS Dataset One'),
                                         approved: nil)
    project.project_datasets << project_dataset

    assert_equal 1, ProjectDataset.dataset_approval(users(:cas_dataset_approver)).count

    project_dataset.approved = true
    project_dataset.save!

    assert_equal 1, ProjectDataset.dataset_approval(users(:cas_dataset_approver)).count

    project_dataset.approved = true
    project_dataset.save!

    assert_equal 1, ProjectDataset.dataset_approval(users(:cas_dataset_approver)).count
  end

  test 'dataset_approval scope should only return approved status is nil if passed that argument' do
    project = Project.create(project_type: project_types(:cas), owner: users(:standard_user2))
    project_dataset = ProjectDataset.new(dataset: Dataset.find_by(name: 'Extra CAS Dataset One'),
                                         approved: nil)
    project.project_datasets << project_dataset

    assert_equal 1, ProjectDataset.dataset_approval(users(:cas_dataset_approver), nil).count

    project_dataset.approved = true
    project_dataset.save!

    assert_equal 0, ProjectDataset.dataset_approval(users(:cas_dataset_approver), nil).count
  end

  test 'should only auto-transition cas application if there are no unresolved dataset decisions' do
    application = Project.new(project_type: ProjectType.find_by(name: 'CAS')).tap do |a|
      a.owner = users(:no_roles)
      a.project_datasets << ProjectDataset.new(dataset: dataset(83), terms_accepted: true,
                                               approved: nil)
      a.project_datasets << ProjectDataset.new(dataset: dataset(84), terms_accepted: true,
                                               approved: nil)
      a.transition_to!(workflow_states(:submitted))
      a.save!
    end

    refute_equal application.current_state, workflow_states(:awaiting_account_approval)

    application.project_datasets.first.update(approved: true)

    refute_equal application.current_state, workflow_states(:awaiting_account_approval)

    application.project_datasets.last.update(approved: false)

    assert_equal application.current_state, workflow_states(:awaiting_account_approval)

    application.project_datasets.last.update(approved: true)

    assert_equal 1, application.states.where(id: "AWAITING_ACCOUNT_APPROVAL").count
  end

  test 'should not auto-transition cas application if not at submitted state' do
    application = Project.new(project_type: ProjectType.find_by(name: 'CAS')).tap do |a|
      a.owner = users(:no_roles)
      a.project_datasets << ProjectDataset.new(dataset: dataset(83), terms_accepted: true,
                                               approved: nil)
      a.project_datasets << ProjectDataset.new(dataset: dataset(84), terms_accepted: true,
                                               approved: nil)
      a.save!
    end

    application.project_datasets.first.update(approved: true)
    application.project_datasets.last.update(approved: false)

    refute_equal application.current_state, workflow_states(:awaiting_account_approval)
  end

  test 'should notify cas manager and access approvers on approved update' do
    project = create_project(project_type: project_types(:cas), project_purpose: 'test')
    dataset = Dataset.find_by(name: 'Extra CAS Dataset One')
    project_dataset = ProjectDataset.new(dataset: dataset, terms_accepted: nil, approved: nil)
    project.project_datasets << project_dataset
    project.reload_current_state

    notifications = Notification.where(title: 'Dataset Approval Status Change')

    # Should not send out notifications for changes when at Draft
    assert_no_difference 'notifications.count' do
      project_dataset.update(terms_accepted: true)
    end

    project.transition_to!(workflow_states(:submitted))
    project.reload_current_state

    assert_difference 'notifications.count', 3 do
      project_dataset.update(approved: true)
    end

    assert_equal notifications.last.body, "CAS project #{project.id} - Dataset 'Extra CAS " \
                                          "Dataset One' has been updated to Approval status of " \
                                          "'Approved'.\n\n"

    assert_difference 'notifications.count', 3 do
      project_dataset.update(approved: false)
    end

    assert_equal notifications.last.body, "CAS project #{project.id} - Dataset 'Extra CAS " \
                                          "Dataset One' has been updated to Approval status of " \
                                          "'Rejected'.\n\n"

    assert_difference 'notifications.count', 3 do
      project_dataset.update(approved: nil)
    end

    assert_equal notifications.last.body, "CAS project #{project.id} - Dataset 'Extra CAS " \
                                          "Dataset One' has been updated to Approval status of " \
                                          "'Undecided'.\n\n"
  end

  test 'should notify user on approved update' do
    project = create_project(project_type: project_types(:cas), project_purpose: 'test',
                             owner: users(:no_roles))
    dataset = Dataset.find_by(name: 'Extra CAS Dataset One')
    project_dataset = ProjectDataset.new(dataset: dataset, terms_accepted: nil, approved: nil)
    project.project_datasets << project_dataset
    project.reload_current_state

    notifications = Notification.where(title: 'Dataset Approval Updated')

    # Should not send out notifications for changes when at Draft
    assert_no_difference 'notifications.count' do
      project_dataset.update(terms_accepted: true)
    end

    project.transition_to!(workflow_states(:submitted))
    project.reload_current_state

    assert_difference 'notifications.count', 1 do
      project_dataset.update(approved: true)
    end

    assert_equal notifications.last.body, "Your CAS dataset access request for 'Extra CAS " \
                                          "Dataset One' has been updated to Approval status of " \
                                          "'Approved'.\n\n"

    assert_difference 'notifications.count', 1 do
      project_dataset.update(approved: false)
    end

    assert_equal notifications.last.body, "Your CAS dataset access request for 'Extra CAS " \
                                          "Dataset One' has been updated to Approval status of " \
                                          "'Rejected'.\n\n"

    assert_difference 'notifications.count', 1 do
      project_dataset.update(approved: nil)
    end

    assert_equal notifications.last.body, "Your CAS dataset access request for 'Extra CAS " \
                                          "Dataset One' has been updated to Approval status of " \
                                          "'Undecided'.\n\n"
  end
end
