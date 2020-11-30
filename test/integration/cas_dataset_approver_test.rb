require 'test_helper'

class CasDatasetApproverTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:cas_dataset_approver)
  end

  test 'should be able to view list of projects that user has access to approve' do
    sign_in @user

    project = Project.create(project_type: project_types(:cas),
        owner: users(:standard_user2))
    dataset = Dataset.find_by(name: 'Extra CAS Dataset One')
    project.project_datasets << ProjectDataset.new(dataset: dataset, terms_accepted: true)

    project.transition_to!(workflow_states(:submitted))
    visit dataset_approvals_projects_path

    within '#awaiting_approval' do
      assert has_content?("#{project.id}")
      click_link(href: "/projects/#{project.id}", title: 'Details')
    end

    click_link(href: "#datasets")
    assert has_content?('Extra CAS Dataset One')

    assert_nil project.project_datasets.first.approved

    project_changes = { from: 'SUBMITTED', to: 'AWAITING_ACCOUNT_APPROVAL' }

    project_dataset = project.project_datasets.first

    assert_changes -> { project.reload.current_state.id }, project_changes do
      assert_changes -> { project_dataset.reload.approved }, from: nil, to: true do
        find('.btn-success').click
        assert has_content?('APPROVED')
      end
      assert has_content?('AWAITING_ACCOUNT_APPROVAL')
    end

    click_link('X')

    assert find('.btn-danger')
    assert find('.btn-success')
    assert_nil project_dataset.reload.approved

    assert_no_changes -> { project.reload.current_state.id } do
      assert_changes -> { project_dataset.reload.approved }, from: nil, to: false do
        find('.btn-danger').click
        assert has_content?('DECLINED')
      end
    end
  end
end
