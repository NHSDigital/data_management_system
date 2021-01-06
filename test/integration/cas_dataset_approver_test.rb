require 'test_helper'

class CasDatasetApproverTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:cas_dataset_approver)
  end

  test 'should be able to view list of projects that user has access to approve' do
    ProjectDatasetsController.any_instance.expects(:valid_otp?).twice.returns(false).then.returns(true)
    sign_in @user

    project = Project.create(project_type: project_types(:cas),
                             owner: users(:standard_user2))
    dataset = Dataset.find_by(name: 'Extra CAS Dataset One')
    project.project_datasets << ProjectDataset.new(dataset: dataset, terms_accepted: true)

    project.transition_to!(workflow_states(:submitted))
    visit dataset_approvals_projects_path

    within '#awaiting_approval' do
      assert has_content?(project.id.to_s)
      click_link(href: "/projects/#{project.id}", title: 'Details')
    end

    click_link(href: '#datasets')
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
end
