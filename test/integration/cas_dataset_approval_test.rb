require 'test_helper'

class CasDatasetApprovalTest < ActionDispatch::IntegrationTest
  test 'should be able to approve and reject datasets' do
    user = users(:cas_dataset_approver)
    ProjectDatasetsController.any_instance.expects(:valid_otp?).twice.returns(false).then.returns(true)
    sign_in user

    project = create_cas_project(owner: users(:standard_user2))
    dataset = Dataset.find_by(name: 'Extra CAS Dataset One')
    project.project_datasets << ProjectDataset.new(dataset: dataset, terms_accepted: true)

    project.transition_to!(workflow_states(:submitted))
    visit cas_approvals_projects_path

    within '#my_dataset_approvals' do
      assert has_content?(project.id.to_s)
      click_link(href: "/projects/#{project.id}#!datasets", title: 'Details')
    end

    assert has_content?('Extra CAS Dataset One')

    assert_nil project.project_datasets.first.approved

    project_dataset = project.project_datasets.first

    assert_changes -> { project_dataset.reload.approved }, from: nil, to: true do
      within('#approvals') do
        find("#approval_project_dataset_#{project_dataset.id}").click
      end
      within_modal(selector: '#yubikey-challenge') do
        fill_in 'ndr_authenticate[otp]', with: 'defo a yubikey'
        click_button 'Submit'
      end
      assert has_content?('APPROVED')
    end

    assert_equal find('#project_status').text, 'Pending'

    click_link('X')

    assert find('.btn-danger')
    assert find('.btn-success')
    assert_nil project_dataset.reload.approved

    assert_changes -> { project_dataset.reload.approved }, from: nil, to: false do
      find('.btn-danger').click
      assert has_content?('DECLINED')
    end

    assert_equal find('#project_status').text, 'Pending'
  end

  test 'should be able to reapply for a dataset if approval declined' do
    user = users(:no_roles)
    sign_in user

    project = create_cas_project(owner: users(:no_roles))
    project_dataset = ProjectDataset.new(dataset: Dataset.find_by(name: 'Extra CAS Dataset One'),
                                         terms_accepted: true)
    project.project_datasets << project_dataset

    project.transition_to!(workflow_states(:submitted))

    project_dataset.approved = true
    project_dataset.save!(validate: false)

    visit project_path(project)

    click_link(href: '#datasets')
    assert has_content?('Extra CAS Dataset One')
    assert_equal find('#dataset_status').text, 'APPROVED'
    assert has_no_content?('Reapply')

    project_dataset.approved = false
    project_dataset.save!(validate: false)

    visit project_path(project)
    click_link(href: '#datasets')
    assert has_content?('Extra CAS Dataset One')

    assert_equal find('#dataset_status').text, 'DECLINED'
    click_link('Reapply')

    assert has_content?('PENDING')
    assert has_no_css?('.btn-danger')
    assert has_no_css?('.btn-success')
    assert_nil project_dataset.reload.approved
  end

  test 'should show applicant correct pending dataset status' do
    # Other statuses are covered in the test above
    user = users(:no_roles)
    sign_in user

    project = create_cas_project(owner: users(:no_roles))
    project_dataset = ProjectDataset.new(dataset: Dataset.find_by(name: 'Extra CAS Dataset One'),
                                         terms_accepted: nil)
    project.project_datasets << project_dataset

    project.transition_to!(workflow_states(:submitted))

    visit project_path(project)

    click_link(href: '#datasets')
    assert has_content?('Extra CAS Dataset One')
    assert_equal find('#dataset_status').text, 'PENDING'
  end

  test 'should show cas_dataset approver correct dataset statuses' do
    user = users(:cas_dataset_approver)
    sign_in user

    project = create_cas_project(owner: users(:standard_user2))
    grant_dataset = ProjectDataset.new(dataset: Dataset.find_by(name: 'Extra CAS Dataset One'),
                                       terms_accepted: true)
    non_grant_dataset = ProjectDataset.new(dataset: Dataset.find_by(name: 'Extra CAS Dataset Two'),
                                           terms_accepted: true)
    project.project_datasets << grant_dataset
    project.project_datasets << non_grant_dataset

    project.transition_to!(workflow_states(:submitted))

    visit project_path(project)

    click_link(href: '#datasets')
    assert has_content?('Extra CAS Dataset One')
    assert has_content?('Extra CAS Dataset Two')

    within("#project_dataset_#{grant_dataset.id}") do
      assert has_css?('.btn-danger')
      assert has_css?('.btn-success')
      assert has_no_content?('PENDING')
    end

    within("#project_dataset_#{non_grant_dataset.id}") do
      assert has_no_css?('.btn-danger')
      assert has_no_css?('.btn-success')
      assert_equal find('#dataset_status').text, 'PENDING'
    end

    non_grant_dataset.approved = true
    non_grant_dataset.save!(validate: false)

    visit project_path(project)

    click_link(href: '#datasets')

    within("#project_dataset_#{non_grant_dataset.id}") do
      assert has_no_css?('.btn-danger')
      assert has_no_css?('.btn-success')
      assert_equal find('#dataset_status').text, 'APPROVED'
    end

    non_grant_dataset.approved = false
    non_grant_dataset.save!(validate: false)

    visit project_path(project)

    click_link(href: '#datasets')

    within("#project_dataset_#{non_grant_dataset.id}") do
      assert has_no_css?('.btn-danger')
      assert has_no_css?('.btn-success')
      assert_equal find('#dataset_status').text, 'DECLINED'
    end
  end
end
