require 'test_helper'

class CasNotifierTest < ActiveSupport::TestCase
  test 'should generate dataset_approved_status_updated Notifications' do
    project = create_project(project_type: project_types(:cas), project_purpose: 'test')
    dataset = Dataset.find_by(name: 'Extra CAS Dataset One')
    project_dataset = ProjectDataset.new(dataset: dataset, terms_accepted: true, approved: true)
    project.project_datasets << project_dataset
    recipients = SystemRole.cas_manager_and_access_approvers.map(&:users).flatten
    title = 'Dataset Approval Status Change'
    assert_difference -> { Notification.by_title(title).count }, 3 do
      recipients.each do |user|
        CasNotifier.dataset_approved_status_updated(project, project_dataset, user.id)
      end
    end

    # TODO Should it be creating UserNotifications?

    assert_equal Notification.last.body, "CAS application #{project.id} - Dataset 'Extra CAS " \
                                         "Dataset One' has been updated to Approval status of " \
                                         "'Approved'.\n\n"
  end

  test 'should generate dataset_approved_status_updated_to_user Notifications' do
    project = create_project(project_type: project_types(:cas), project_purpose: 'test',
                             owner: users(:no_roles))
    dataset = Dataset.find_by(name: 'Extra CAS Dataset One')
    project_dataset = ProjectDataset.new(dataset: dataset, terms_accepted: true, approved: true)
    project.project_datasets << project_dataset
    assert_difference -> { Notification.by_title('Dataset Approval Updated').count }, 1 do
      CasNotifier.dataset_approved_status_updated_to_user(project, project_dataset)
    end

    # TODO Should it be creating UserNotifications?

    assert_equal Notification.last.body, "Your CAS dataset access request for 'Extra CAS " \
                                         "Dataset One' has been updated to Approval status of " \
                                         "'Approved'.\n\n"
  end

  test 'should generate access_approval_status_updated Notifications' do
    project = create_project(project_type: project_types(:cas), project_purpose: 'test')
    project.transition_to!(workflow_states(:submitted))
    project.transition_to!(workflow_states(:access_approver_approved))
    recipients = SystemRole.cas_manager_and_access_approvers.map(&:users).flatten
    title = 'Access Approval Status Updated'
    assert_difference -> { Notification.by_title(title).count }, 3 do
      recipients.each do |user|
        CasNotifier.access_approval_status_updated(project, user.id)
      end
    end

    # TODO Should it be creating UserNotifications?

    assert_equal Notification.last.body, "CAS application #{project.id} - Access approval status has " \
                                         "been updated to 'Access Approver Approved'.\n\n"
  end

  test 'should generate account_approved_to_user Notifications' do
    user = users(:no_roles)
    project = create_project(project_type: project_types(:cas), project_purpose: 'test',
                             owner: user)
    assert_difference -> { Notification.by_title('CAS Access Approved').count }, 1 do
      CasNotifier.account_approved_to_user(project)
    end

    # TODO Should it be creating UserNotifications?

    assert_equal Notification.last.body, "Your CAS access has been approved for application " \
                                         "#{project.id}. You will receive a further notification " \
                                         "once your account has been updated.\n\n"
  end

  test 'should generate account_rejected_to_user Notifications' do
    user = users(:no_roles)
    project = create_project(project_type: project_types(:cas), project_purpose: 'test',
                             owner: user)
    assert_difference -> { Notification.by_title('CAS Access Rejected').count }, 1 do
      CasNotifier.account_rejected_to_user(project)
    end

    # TODO: Should it be creating UserNotifications?

    assert_equal Notification.last.body, 'Your CAS access has been rejected for application ' \
                                         "#{project.id}.\n\n"
  end

  test 'should generate account_access_granted Notifications' do
    project = create_project(project_type: project_types(:cas), project_purpose: 'test')

    recipients = SystemRole.fetch(:cas_manager).users

    title = 'CAS Access Status Updated'
    assert_difference -> { Notification.by_title(title).count }, 2 do
      recipients.each do |user|
        CasNotifier.account_access_granted(project, user.id)
      end
    end

    # TODO Should it be creating UserNotifications?
    expected = "CAS application #{project.id} - Access has been granted " \
               "by the helpdesk and the applicant now has CAS access.\n\n"
    assert_equal Notification.last.body, expected
  end

  test 'should generate account_access_granted_to_user Notifications' do
    user = users(:no_roles)
    project = create_project(project_type: project_types(:cas), project_purpose: 'test',
                             owner: user)

    assert_difference -> { Notification.by_title('CAS Access Granted').count }, 1 do
      CasNotifier.account_access_granted_to_user(project)
    end

    # TODO Should it be creating UserNotifications?

    assert_equal Notification.last.body, "CAS access has been granted for your account based on " \
                                         "application #{project.id}.\n\n"
  end

  test 'should generate requires_account_approval Notifications' do
    project = create_project(project_type: project_types(:cas), project_purpose: 'test')
    title = 'CAS Application Requires Access Approval'
    assert_difference -> { Notification.by_title(title).count }, 1 do
      User.cas_access_approvers.each do |user|
        CasNotifier.requires_account_approval(project, user.id)
      end
    end

    # TODO: Should it be creating UserNotifications?

    assert_equal Notification.last.body, "CAS application #{project.id} - Access approval is " \
                                         "required.\n\n"
  end

  test 'should generate requires_dataset_approval Notifications' do
    project = Project.new(project_type: ProjectType.find_by(name: 'CAS')).tap do |a|
      a.owner = users(:no_roles)
      a.project_datasets << ProjectDataset.new(dataset: dataset(83), terms_accepted: true)
      a.project_datasets << ProjectDataset.new(dataset: dataset(84), terms_accepted: true)
      a.save!
    end
    title = 'CAS Application Requires Dataset Approval'
    assert_difference -> { Notification.by_title(title).count }, 2 do
      project.datasets.each do |dataset|
        dataset.approvers.each do |approver|
          CasNotifier.requires_dataset_approval(project, approver.id)
        end
      end
    end

    # TODO: Should it be creating UserNotifications?
    assert_equal Notification.last.body, "CAS application #{project.id} - Dataset approval is " \
                                         "required.\n\n"
  end

  test 'should generate application_submitted Notifications' do
    project = create_project(project_type: project_types(:cas), project_purpose: 'test')

    recipients = SystemRole.fetch(:cas_manager).users
    title = 'CAS Application Submitted'

    assert_difference -> { Notification.by_title(title).count }, 2 do
      recipients.each do |user|
        CasNotifier.application_submitted(project, user.id)
      end
    end

    # TODO: Should it be creating UserNotifications?

    assert_equal Notification.last.body, "CAS project #{project.id} has been submitted.\n\n"
  end
end
