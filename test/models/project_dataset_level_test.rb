require 'test_helper'

class ProjectDatasetLevelTest < ActiveSupport::TestCase
  test 'should notify casmanager and access approvers on dataset level approved update - not nil' do
    project = create_cas_project(project_purpose: 'test')
    dataset = Dataset.find_by(name: 'Extra CAS Dataset One')
    project_dataset = ProjectDataset.new(dataset: dataset, terms_accepted: nil)
    project.project_datasets << project_dataset
    pdl = ProjectDatasetLevel.new(access_level_id: 1, expiry_date: Time.zone.today + 1.week, approved: nil)
    project_dataset.project_dataset_levels << pdl
    project.reload_current_state

    notifications = Notification.where(title: 'Dataset Approval Level Status Change')

    # Should not send out notifications for changes when at Draft
    assert_no_difference 'notifications.count' do
      pdl.update(approved: true)
      pdl.update(approved: nil)
    end

    project.transition_to!(workflow_states(:submitted))
    project.reload_current_state

    assert_difference 'notifications.count', 4 do
      pdl.update(approved: true)
    end

    assert_equal notifications.last.body, "CAS application #{project.id} - Dataset 'Extra CAS " \
                                          "Dataset One' has been updated to Approval status of " \
                                          "'Approved' for level 1.\n\n"

    assert_difference 'notifications.count', 4 do
      pdl.update(approved: false)
    end

    assert_equal notifications.last.body, "CAS application #{project.id} - Dataset 'Extra CAS " \
                                          "Dataset One' has been updated to Approval status of " \
                                          "'Rejected' for level 1.\n\n"

    assert_no_difference 'notifications.count' do
      pdl.update(approved: nil)
    end
  end

  test 'should notify user on dataset level approved update to not nil' do
    project = create_cas_project(project_purpose: 'test', owner: users(:no_roles))
    dataset = Dataset.find_by(name: 'Extra CAS Dataset One')
    project_dataset = ProjectDataset.new(dataset: dataset, terms_accepted: nil)
    project.project_datasets << project_dataset
    pdl = ProjectDatasetLevel.new(access_level_id: 1, expiry_date: Time.zone.today + 1.week, approved: nil)
    project_dataset.project_dataset_levels << pdl
    project.reload_current_state

    notifications = Notification.where(title: 'Dataset Approval Level Updated')

    # Should not send out notifications for changes when at Draft
    assert_no_difference 'notifications.count' do
      pdl.update(approved: true)
      pdl.update(approved: nil)
    end

    project.transition_to!(workflow_states(:submitted))
    project.reload_current_state

    assert_difference 'notifications.count', 1 do
      pdl.update(approved: true)
    end

    assert_equal notifications.last.body, "Your CAS dataset access request for 'Extra CAS " \
                                          "Dataset One' has been updated to Approval status of " \
                                          "'Approved' for level 1.\n\n"

    assert_difference 'notifications.count', 1 do
      pdl.update(approved: false)
    end

    assert_equal notifications.last.body, "Your CAS dataset access request for 'Extra CAS " \
                                          "Dataset One' has been updated to Approval status of " \
                                          "'Rejected' for level 1.\n\n"

    assert_no_difference 'notifications.count' do
      pdl.update(approved: nil)
    end
  end

  test 'should not notify dataset approver on dataset level approved update to nil' do
    project_dataset = ProjectDataset.new(dataset: dataset(83), terms_accepted: true)
    project = create_cas_project(owner: users(:no_roles))
    project.project_datasets << project_dataset
    pdl = ProjectDatasetLevel.new(access_level_id: 1, expiry_date: Time.zone.today + 1.week,
                                  approved: true)
    project_dataset.project_dataset_levels << pdl

    project.transition_to!(workflow_states(:submitted))

    assert_no_difference 'notifications.count' do
      pdl.update(approved: nil)
    end
  end

  test 'set_decided_at_to_nil' do
    date_time_now = Time.zone.now
    project_dataset = ProjectDataset.new(dataset: dataset(83), terms_accepted: true)
    project = create_cas_project(owner: users(:no_roles))
    project.project_datasets << project_dataset
    pdl = ProjectDatasetLevel.new(access_level_id: 1, expiry_date: Time.zone.today + 1.week,
                                  approved: true, decided_at: date_time_now)
    project_dataset.project_dataset_levels << pdl

    project.transition_to!(workflow_states(:submitted))

    assert_equal pdl.decided_at, date_time_now

    pdl.update(approved: nil)

    assert_nil pdl.decided_at
  end
end
