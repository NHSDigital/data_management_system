require 'test_helper'

# Tests behaviour of ProjectsMailer
class ProjectsMailerTest < ActionMailer::TestCase
  test 'dataset approved level status updated' do
    project = create_cas_project(project_purpose: 'test')
    dataset = Dataset.find_by(name: 'Extra CAS Dataset One')
    project_dataset = ProjectDataset.new(dataset: dataset, terms_accepted: true)
    project.project_datasets << project_dataset
    pdl = ProjectDatasetLevel.new(access_level_id: 1, expiry_date: Time.zone.today + 1.week,
                                  approved: true)
    project_dataset.project_dataset_levels << pdl

    email = CasMailer.with(project: project, project_dataset_level: pdl).dataset_level_approved_status_updated

    assert_emails 1 do
      email.deliver_later
    end

    assert_equal User.cas_manager_and_access_approvers.map(&:email), email.to
    assert_equal 'Dataset Approval Level Status Change', email.subject
    assert_match %r{a href="http://[^/]+/projects/#{project.id}"}, email.html_part.body.to_s
    assert_match %r{http://[^/]+/projects/#{project.id}}, email.text_part.body.to_s
  end

  test 'dataset approved status updated_to_user' do
    project = create_cas_project(project_purpose: 'test')
    dataset = Dataset.find_by(name: 'Extra CAS Dataset One')
    project_dataset = ProjectDataset.new(dataset: dataset, terms_accepted: true)
    project.project_datasets << project_dataset
    pdl = ProjectDatasetLevel.new(access_level_id: 1, expiry_date: Time.zone.today + 1.week,
                                  approved: true)
    project_dataset.project_dataset_levels << pdl

    email = CasMailer.with(project: project, project_dataset_level: pdl).dataset_level_approved_status_updated_to_user

    assert_emails 1 do
      email.deliver_later
    end

    assert_equal Array.wrap(project.owner.email), email.to
    assert_equal 'Dataset Approval Level Updated', email.subject
    assert_match %r{http://[^/]+/projects/#{project.id}}, email.text_part.body.to_s
  end

  test 'access approval status updated' do
    project = create_cas_project(project_purpose: 'test')
    project.transition_to!(workflow_states(:submitted))

    project.transition_to!(workflow_states(:access_approver_approved))

    email = CasMailer.with(project: project).access_approval_status_updated

    assert_emails 1 do
      email.deliver_later
    end

    assert_equal User.cas_manager_and_access_approvers.map(&:email), email.to
    assert_equal 'Access Approval Status Updated', email.subject
    assert_match %r{a href="http://[^/]+/projects/#{project.id}"}, email.html_part.body.to_s
    assert_match %r{http://[^/]+/projects/#{project.id}}, email.text_part.body.to_s
  end

  test 'account approved to user' do
    project = create_cas_project(project_purpose: 'test',
                             owner: users(:no_roles))
    project.transition_to!(workflow_states(:submitted))

    project.transition_to!(workflow_states(:access_approver_approved))

    email = CasMailer.with(project: project).account_approved_to_user

    assert_emails 1 do
      email.deliver_later
    end

    assert_equal Array.wrap(project.owner.email), email.to
    assert_equal 'CAS Access Approved', email.subject
    assert_match %r{http://[^/]+/projects/#{project.id}}, email.text_part.body.to_s
  end

  test 'account rejected to user' do
    project = create_cas_project(project_purpose: 'test', owner: users(:no_roles))
    project.transition_to!(workflow_states(:submitted))
    project.transition_to!(workflow_states(:access_approver_rejected))

    project.transition_to!(workflow_states(:rejection_reviewed))

    email = CasMailer.with(project: project).account_rejected_to_user

    assert_emails 1 do
      email.deliver_later
    end

    assert_equal Array.wrap(project.owner.email), email.to
    assert_equal 'CAS Access Rejected', email.subject
    assert_match %r{http://[^/]+/projects/#{project.id}}, email.text_part.body.to_s
  end

  test 'account access granted to user' do
    project = create_cas_project(project_purpose: 'test', owner: users(:no_roles))

    project.transition_to!(workflow_states(:submitted))
    # Auto-transitions to Access Granted
    project.transition_to!(workflow_states(:access_approver_approved))
    project.reload.current_state

    email = CasMailer.with(project: project).account_access_granted_to_user

    assert_emails 1 do
      email.deliver_later
    end

    assert_equal Array.wrap(project.owner.email), email.to
    assert_equal 'CAS Access Granted', email.subject
    assert_match %r{http://[^/]+/projects/#{project.id}}, email.text_part.body.to_s
  end

  test 'account access granted' do
    project = create_cas_project(project_purpose: 'test', owner: users(:no_roles))

    project.transition_to!(workflow_states(:submitted))
    project.transition_to!(workflow_states(:access_approver_approved))

    email = CasMailer.with(project: project).account_access_granted

    assert_emails 1 do
      email.deliver_later
    end

    assert_equal User.cas_managers.pluck(:email), email.to
    assert_equal 'CAS Access Status Updated', email.subject
    assert_match %r{http://[^/]+/projects/#{project.id}}, email.text_part.body.to_s
  end

  test 'requires account approval' do
    project = create_cas_project(project_purpose: 'test', owner: users(:no_roles))
    project.transition_to!(workflow_states(:submitted))

    email = CasMailer.with(project: project).requires_account_approval

    assert_emails 1 do
      email.deliver_later
    end

    assert_equal User.cas_access_approvers.pluck(:email), email.to
    assert_equal 'CAS Application Requires Access Approval', email.subject
    assert_match %r{http://[^/]+/projects/#{project.id}}, email.text_part.body.to_s
  end

  test 'requires dataset approval' do
    project = create_cas_project(project_purpose: 'test', owner: users(:no_roles))
    dataset = Dataset.find_by(name: 'Extra CAS Dataset One')
    project_dataset = ProjectDataset.new(dataset: dataset, terms_accepted: true)
    project.project_datasets << project_dataset
    pdl = ProjectDatasetLevel.new(access_level_id: 1, expiry_date: Time.zone.today + 1.week,
                                  approved: nil)
    project_dataset.project_dataset_levels << pdl

    project.transition_to!(workflow_states(:submitted))

    email = CasMailer.with(project: project, user: DatasetRole.fetch(:approver).users.first).requires_dataset_approval

    assert_emails 1 do
      email.deliver_later
    end

    assert_equal Array.wrap(DatasetRole.fetch(:approver).users.first.email), email.to
    assert_equal 'CAS Application Requires Dataset Approval', email.subject
    assert_match %r{http://[^/]+/projects/#{project.id}}, email.text_part.body.to_s
  end

  test 'application submitted' do
    project = create_cas_project(project_purpose: 'test', owner: users(:no_roles))
    project.transition_to!(workflow_states(:submitted))

    email = CasMailer.with(project: project).application_submitted

    assert_emails 1 do
      email.deliver_later
    end

    assert_equal User.cas_managers.pluck(:email), email.to
    assert_equal 'CAS Application Submitted', email.subject
    assert_match %r{http://[^/]+/projects/#{project.id}}, email.text_part.body.to_s
  end

  test 'requires renewal to user' do
    project = create_cas_project(project_purpose: 'test',
                             owner: users(:no_roles))

    email = CasMailer.with(project: project).requires_renewal_to_user

    assert_emails 1 do
      email.deliver_later
    end

    assert_equal Array.wrap(project.owner.email), email.to
    assert_equal 'CAS Access Requires Renewal', email.subject
    assert_match %r{http://[^/]+/projects/#{project.id}}, email.text_part.body.to_s
  end

  test 'requires renewal midpoint to user' do
    project = create_cas_project(project_purpose: 'test',
                             owner: users(:no_roles))

    email = CasMailer.with(project: project).requires_renewal_midpoint_to_user

    assert_emails 1 do
      email.deliver_later
    end

    assert_equal Array.wrap(project.owner.email), email.to
    assert_equal 'CAS Access Urgently Requires Renewal', email.subject
    assert_match %r{http://[^/]+/projects/#{project.id}}, email.text_part.body.to_s
  end

  test 'account closed to user' do
    project = create_cas_project(project_purpose: 'test',
                             owner: users(:no_roles))

    email = CasMailer.with(project: project).account_closed_to_user

    assert_emails 1 do
      email.deliver_later
    end

    assert_equal Array.wrap(project.owner.email), email.to
    assert_equal 'CAS Account Closed', email.subject
    assert_match %r{http://[^/]+/projects/#{project.id}}, email.text_part.body.to_s
  end

  test 'account closed' do
    project = create_cas_project(project_purpose: 'test', owner: users(:no_roles))

    email = CasMailer.with(project: project).account_closed

    assert_emails 1 do
      email.deliver_later
    end

    assert_equal User.cas_managers.pluck(:email), email.to
    assert_equal 'CAS Account Has Closed', email.subject
    assert_match %r{http://[^/]+/projects/#{project.id}}, email.text_part.body.to_s
  end

  test 'account renewed' do
    project = create_cas_project(project_purpose: 'test')

    email = CasMailer.with(project: project).account_renewed

    assert_emails 1 do
      email.deliver_later
    end

    assert_equal User.cas_manager_and_access_approvers.map(&:email), email.to
    assert_equal 'CAS Account Renewed', email.subject
    assert_match %r{http://[^/]+/projects/#{project.id}}, email.text_part.body.to_s
  end

  test 'account renewed dataset approver' do
    project = create_cas_project(project_purpose: 'test', owner: users(:no_roles))

    dataset = Dataset.find_by(name: 'Extra CAS Dataset One')
    project_dataset = ProjectDataset.new(dataset: dataset, terms_accepted: true)
    project.project_datasets << project_dataset
    pdl = ProjectDatasetLevel.new(access_level_id: 1, expiry_date: Time.zone.today + 1.week)
    project_dataset.project_dataset_levels << pdl
    project.transition_to!(workflow_states(:submitted))

    email = CasMailer.with(project: project, user: DatasetRole.fetch(:approver).users.first).account_renewed_dataset_approver

    assert_emails 1 do
      email.deliver_later
    end

    assert_equal Array.wrap(DatasetRole.fetch(:approver).users.first.email), email.to
    assert_equal 'CAS Account Renewed With Access to Dataset', email.subject
    assert_match %r{http://[^/]+/projects/#{project.id}}, email.text_part.body.to_s
  end

  test 'new cas project saved' do
    project = create_cas_project(project_purpose: 'test',
                             owner: users(:no_roles))

    email = CasMailer.with(project: project).new_cas_project_saved

    assert_emails 1 do
      email.deliver_later
    end

    assert_equal User.cas_managers.pluck(:email), email.to
    assert_equal 'New CAS Application Created', email.subject
    assert_match %r{http://[^/]+/projects/#{project.id}}, email.text_part.body.to_s
  end
end
