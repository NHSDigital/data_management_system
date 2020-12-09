require 'test_helper'

class CasNotifierTest < ActiveSupport::TestCase
  test 'should generate dataset_approved_status_updated Notifications' do
    project = create_project(project_type: project_types(:cas), project_purpose: 'test')
    dataset = Dataset.find_by(name: 'Extra CAS Dataset One')
    project_dataset = ProjectDataset.new(dataset: dataset, terms_accepted: true, approved: true)
    project.project_datasets << project_dataset
    recipients = SystemRole.cas_manager_and_access_approvers.map(&:users).flatten
    notification = Notification.where(title: 'Dataset Approval Status Change')

    assert_difference -> { notification.count }, 3 do
      recipients.each do |user|
        CasNotifier.dataset_approved_status_updated(project, project_dataset, user.id)
      end
    end

    # TODO Should it be creating UserNotifications?

    assert_equal notification.last.body, "CAS project #{project.id} - Dataset 'Extra CAS " \
                                         "Dataset One' has been updated to Approval status of " \
                                         "'Approved'.\n\n"
  end

  test 'should generate dataset_approved_status_updated_to_user Notifications' do
    project = create_project(project_type: project_types(:cas), project_purpose: 'test',
                             owner: users(:no_roles))
    dataset = Dataset.find_by(name: 'Extra CAS Dataset One')
    project_dataset = ProjectDataset.new(dataset: dataset, terms_accepted: true, approved: true)
    project.project_datasets << project_dataset
    notification = Notification.where(title: 'Dataset Approval Updated')

    assert_difference -> { notification.count }, 1 do
      CasNotifier.dataset_approved_status_updated_to_user(project, project_dataset)
    end

    # TODO Should it be creating UserNotifications?

    assert_equal notification.last.body, "Your CAS dataset access request for 'Extra CAS " \
                                         "Dataset One' has been updated to Approval status of " \
                                         "'Approved'.\n\n"
  end

  test 'should generate access_approval_status_updated Notifications' do
    project = create_project(project_type: project_types(:cas), project_purpose: 'test')
    project.transition_to!(workflow_states(:awaiting_account_approval))

    project.transition_to!(workflow_states(:approved))
    recipients = SystemRole.cas_manager_and_access_approvers.map(&:users).flatten
    notification = Notification.where(title: 'Access Approval Status Updated')

    assert_difference -> { notification.count }, 3 do
      recipients.each do |user|
        CasNotifier.access_approval_status_updated(project, user.id)
      end
    end

    # TODO Should it be creating UserNotifications?

    assert_equal notification.last.body, "CAS project #{project.id} - Access approval status has " \
                                         "been updated to 'Approved'.\n\n"
  end

  test 'should generate account_approved_to_user Notifications' do
    user = users(:no_roles)
    project = create_project(project_type: project_types(:cas), project_purpose: 'test',
                             owner: user)
    notification = Notification.where(title: 'CAS Access Approved')

    assert_difference -> { notification.count }, 1 do
      CasNotifier.account_approved_to_user(project)
    end

    # TODO Should it be creating UserNotifications?

    assert_equal notification.last.body, "Your CAS access has been approved for application " \
                                         "#{project.id}. You will receive a further notification " \
                                         "once your account has been updated"
  end

  test 'should generate account_access_granted Notifications' do
    project = create_project(project_type: project_types(:cas), project_purpose: 'test')

    recipients = SystemRole.fetch(:cas_manager).users
    notification = Notification.where(title: 'CAS Access Status Updated')

    assert_difference -> { notification.count }, 2 do
      recipients.each do |user|
        CasNotifier.account_access_granted(project, user.id)
      end
    end

    # TODO Should it be creating UserNotifications?

    assert_equal notification.last.body, "CAS project #{project.id} - Access has been granted by " \
                                         "the helpdesk and the applicant now has CAS access.\n\n"
  end

  test 'should generate account_access_granted_to_user Notifications' do
    user = users(:no_roles)
    project = create_project(project_type: project_types(:cas), project_purpose: 'test',
                             owner: user)
    notification = Notification.where(title: 'CAS Access Granted')

    assert_difference -> { notification.count }, 1 do
      CasNotifier.account_access_granted_to_user(project)
    end

    # TODO Should it be creating UserNotifications?

    assert_equal notification.last.body, "CAS access has been granted for your account based on " \
                                         "application #{project.id}."
  end
end
