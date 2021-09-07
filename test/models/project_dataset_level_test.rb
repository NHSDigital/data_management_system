require 'test_helper'

class ProjectDatasetLevelTest < ActiveSupport::TestCase
  test 'should notify casmanager and access approvers on dataset level approved update - not nil' do
    project = create_cas_project(project_purpose: 'test')
    dataset = Dataset.find_by(name: 'Extra CAS Dataset One')
    project_dataset = ProjectDataset.new(dataset: dataset, terms_accepted: nil)
    project.project_datasets << project_dataset
    pdl = ProjectDatasetLevel.create(access_level_id: 1, expiry_date: Time.zone.today + 1.week,
                                     project_dataset_id: project_dataset.id)
    project.reload_current_state

    notifications = Notification.where(title: 'Dataset Approval Level Status Change')

    # Should not send out notifications for changes when at Draft
    assert_no_difference 'notifications.count' do
      pdl.update(status: :approved)
      pdl.update(status: :request)
    end

    project.transition_to!(workflow_states(:submitted))
    project.reload_current_state
    assert_equal 'SUBMITTED', project.current_state&.id

    assert_difference 'notifications.count', 4 do
      pdl.update(status: :approved)
    end

    assert_equal notifications.last.body, "CAS application #{project.id} - Dataset 'Extra CAS " \
                                          "Dataset One' has been updated to Approval status of " \
                                          "'Approved' for level 1.\n\n"

    assert_difference 'notifications.count', 4 do
      pdl.update(status: :rejected)
    end

    assert_equal notifications.last.body, "CAS application #{project.id} - Dataset 'Extra CAS " \
                                          "Dataset One' has been updated to Approval status of " \
                                          "'Rejected' for level 1.\n\n"

    assert_no_difference 'notifications.count' do
      pdl.update(status: :request)
    end
  end

  test 'should notify user on dataset level approved update to not nil' do
    project = create_cas_project(project_purpose: 'test', owner: users(:no_roles))
    dataset = Dataset.find_by(name: 'Extra CAS Dataset One')
    project_dataset = ProjectDataset.new(dataset: dataset, terms_accepted: nil)
    project.project_datasets << project_dataset
    pdl = ProjectDatasetLevel.create(access_level_id: 1, expiry_date: Time.zone.today + 1.week,
                                     project_dataset_id: project_dataset.id)
    project.reload_current_state

    notifications = Notification.where(title: 'Dataset Approval Level Updated')

    # Should not send out notifications for changes when at Draft
    assert_no_difference 'notifications.count' do
      pdl.update(status: :approved)
      pdl.update(status: :request)
    end

    project.transition_to!(workflow_states(:submitted))
    project.reload_current_state

    assert_difference 'notifications.count', 1 do
      pdl.update(status: :approved)
    end

    assert_equal notifications.last.body, "Your CAS dataset access request for 'Extra CAS " \
                                          "Dataset One' has been updated to Approval status of " \
                                          "'Approved' for level 1.\n\n"

    assert_difference 'notifications.count', 1 do
      pdl.update(status: :rejected)
    end

    assert_equal notifications.last.body, "Your CAS dataset access request for 'Extra CAS " \
                                          "Dataset One' has been updated to Approval status of " \
                                          "'Rejected' for level 1.\n\n"

    assert_no_difference 'notifications.count' do
      pdl.update(status: :request)
    end
  end

  test 'should not notify dataset approver on dataset level approved update to nil' do
    project_dataset = ProjectDataset.new(dataset: dataset(83), terms_accepted: true)
    project = create_cas_project(owner: users(:no_roles))
    project.project_datasets << project_dataset
    pdl = ProjectDatasetLevel.create(access_level_id: 1, expiry_date: Time.zone.today + 1.week,
                                     project_dataset_id: project_dataset.id)
    pdl.update(status: :approved)
    project.transition_to!(workflow_states(:submitted))

    assert_no_difference 'notifications.count' do
      pdl.update(status: :request)
    end
  end

  test 'set_decided_at_to_nil' do
    date_time_now = Time.zone.now
    project_dataset = ProjectDataset.new(dataset: dataset(83), terms_accepted: true)
    project = create_cas_project(owner: users(:no_roles))
    project.project_datasets << project_dataset
    pdl = ProjectDatasetLevel.create(access_level_id: 1, expiry_date: Time.zone.today + 1.week,
                                     project_dataset_id: project_dataset.id)
    pdl.update(status: :approved, decided_at: date_time_now)
    project.transition_to!(workflow_states(:submitted))

    assert_equal pdl.decided_at, date_time_now

    pdl.update(status: :request)

    assert_nil pdl.decided_at
  end

  test 'level 2 and 3 default datasets should have expiry date set to 1 year on creation' do
    project_dataset = ProjectDataset.new(dataset: dataset(85), terms_accepted: true)
    assert project_dataset.dataset.cas_defaults?
    project = create_cas_project(owner: users(:no_roles))
    project.project_datasets << project_dataset
    no_expiry_pdl = ProjectDatasetLevel.create(access_level_id: 2,
                                               project_dataset_id: project_dataset.id)

    assert_equal 1.year.from_now.to_date, no_expiry_pdl.expiry_date

    expiry_pdl = ProjectDatasetLevel.create(access_level_id: 3, expiry_date: 2.years.from_now,
                                            project_dataset_id: project_dataset.id)
    assert_equal 1.year.from_now.to_date, expiry_pdl.expiry_date

    wrong_access_level = ProjectDatasetLevel.create(access_level_id: 1,
                                                    project_dataset_id: project_dataset.id)

    refute_equal 1.year.from_now.to_date, wrong_access_level.expiry_date

    project_dataset = ProjectDataset.new(dataset: dataset(83), terms_accepted: true)
    assert project_dataset.dataset.cas_extras?
    project.project_datasets << project_dataset
    wrong_dataset_type_and_date = ProjectDatasetLevel.create(access_level_id: 2,
                                                             expiry_date: 2.years.from_now,
                                                             project_dataset_id: project_dataset.id)

    refute_equal 1.year.from_now.to_date, wrong_dataset_type_and_date.expiry_date

    wrong_dataset_type_no_date = ProjectDatasetLevel.create(access_level_id: 3,
                                                            project_dataset_id: project_dataset.id)

    refute_equal 1.year.from_now.to_date, wrong_dataset_type_no_date.expiry_date
  end

  test 'expiry date must be present for level 1 and extra datasets' do
    project_dataset = ProjectDataset.new(dataset: dataset(85), terms_accepted: true)
    assert project_dataset.dataset.cas_defaults?
    project = create_cas_project(owner: users(:no_roles))
    project.project_datasets << project_dataset
    level_1_default_pdl = ProjectDatasetLevel.new(access_level_id: 1, selected: true)
    project_dataset.project_dataset_levels << level_1_default_pdl

    level_1_default_pdl.valid?
    assert level_1_default_pdl.errors.messages[:expiry_date].
      include?('expiry date must be present for all selected extra datasets and any selected ' \
               'level 1 default datasets')

    level_1_default_pdl.update(expiry_date: 1.month.from_now.to_date)
    level_1_default_pdl.valid?
    refute level_1_default_pdl.errors.messages[:expiry_date].
      include?('expiry date must be present for all selected extra datasets and any selected ' \
               'level 1 default datasets')

    level_2_default_pdl = ProjectDatasetLevel.new(access_level_id: 2, selected: true)
    project_dataset.project_dataset_levels << level_2_default_pdl

    level_2_default_pdl.valid?
    refute level_2_default_pdl.errors.messages[:expiry_date].
      include?('expiry date must be present for all selected extra datasets and any selected ' \
               'level 1 default datasets')

    project_dataset = ProjectDataset.new(dataset: dataset(83), terms_accepted: true)
    assert project_dataset.dataset.cas_extras?
    project.project_datasets << project_dataset

    level_2_extra_pdl = ProjectDatasetLevel.new(access_level_id: 2, selected: true)
    project_dataset.project_dataset_levels << level_2_extra_pdl

    level_2_extra_pdl.valid?
    refute level_2_default_pdl.errors.messages[:expiry_date].
      include?('expiry date must be present for all selected extra datasets and any selected ' \
               'level 1 default datasets')
  end

  test 'should validate uniqueness of status for requested approved and renewable' do
    project = create_cas_project(owner: users(:no_roles))
    project_dataset = ProjectDataset.create(dataset: dataset(86), terms_accepted: true,
                                            project_id: project.id)
    status_1_l2_pdl = ProjectDatasetLevel.create(access_level_id: 2, selected: true,
                                                 project_dataset_id: project_dataset.id)
    status_1_duplicate = ProjectDatasetLevel.create(access_level_id: 3, selected: true,
                                                    project_dataset_id: project_dataset.id)

    # same status and project_dataset but different access_level_id so should not error
    status_1_duplicate.valid?
    refute status_1_duplicate.errors.messages[:status].include?('has already been taken')

    # same access_level_id, status of request and project_dataset so should error
    status_1_duplicate.update(access_level_id: 2)
    status_1_duplicate.valid?
    assert status_1_duplicate.errors.messages[:status].include?('has already been taken')

    # same status and access_level_id but different project_dataset so should not error
    project_dataset2 = ProjectDataset.create(dataset: dataset(85), terms_accepted: true,
                                             project_id: project.id)
    status_1_duplicate.update(project_dataset_id: project_dataset2.id)
    status_1_duplicate.valid?
    refute status_1_duplicate.errors.messages[:status].include?('has already been taken')

    # same project_dataset and access_level_id but different status so should not error
    status_1_duplicate.update(project_dataset_id: project_dataset.id, status: :approved)
    status_1_duplicate.valid?
    refute status_1_duplicate.errors.messages[:status].include?('has already been taken')

    # same access_level_id, status of approved and project_dataset so should error
    status_1_l2_pdl.update(status: :approved)
    status_1_l2_pdl.valid?
    assert status_1_l2_pdl.errors.messages[:status].include?('has already been taken')

    # same project_dataset and access_level_id but different status so should not error
    status_1_l2_pdl.update(status: :rejected)
    status_1_l2_pdl.valid?
    refute status_1_l2_pdl.errors.messages[:status].include?('has already been taken')

    # same project_dataset, status and access_level_id but status is rejected so should not error
    status_1_duplicate.update(status: :rejected)
    status_1_duplicate.valid?
    refute status_1_duplicate.errors.messages[:status].include?('has already been taken')

    # same project_dataset and access_level_id but different status so should not error
    status_1_duplicate.update(status: :renewable)
    status_1_duplicate.valid?
    refute status_1_duplicate.errors.messages[:status].include?('has already been taken')

    # same access_level_id, status of renewable and project_dataset so should error
    status_1_l2_pdl.update(status: :renewable)
    status_1_l2_pdl.valid?
    assert status_1_l2_pdl.errors.messages[:status].include?('has already been taken')
  end
end
