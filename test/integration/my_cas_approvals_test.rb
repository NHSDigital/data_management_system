require 'test_helper'

class MyCasApprovalsTest < ActionDispatch::IntegrationTest
  test 'dataset approver should be able to view list of projects with a dataset they can approve' do
    sign_in users(:cas_dataset_approver)

    grant_project = create_cas_project(owner: users(:standard_user2))
    grant_project_dataset = ProjectDataset.new(dataset: Dataset.find_by(name: 'Extra CAS Dataset One'),
                                               terms_accepted: true)
    grant_project.project_datasets << grant_project_dataset
    grant_project_pdl = ProjectDatasetLevel.new(access_level_id: 1,
                                                expiry_date: Time.zone.today + 1.week)
    grant_project_dataset.project_dataset_levels << grant_project_pdl

    no_grant_project = create_cas_project(owner: users(:standard_user2))
    no_grant_project_dataset = ProjectDataset.new(dataset: Dataset.find_by(name: 'Extra CAS Dataset Two'),
                                                  terms_accepted: true)
    no_grant_project.project_datasets << no_grant_project_dataset
    no_grant_project_pdl = ProjectDatasetLevel.new(access_level_id: 1,
                                                   expiry_date: Time.zone.today + 1.week)
    no_grant_project_dataset.project_dataset_levels << no_grant_project_pdl

    grant_project.transition_to!(workflow_states(:submitted))
    no_grant_project.transition_to!(workflow_states(:submitted))
    visit cas_approvals_projects_path

    within '#my_dataset_approvals' do
      assert has_content?(grant_project.id.to_s)
      assert has_no_content?(no_grant_project.id.to_s)
    end
    # Doesn't have access approver grant so shouldn't see table
    assert has_no_css?('#my_access_approvals')
  end

  test 'access approver should be able to view list of projects with a dataset they can approve' do
    sign_in users(:cas_access_approver)

    submitted_state_project = create_cas_project(owner: users(:standard_user2))
    draft_state_project = create_cas_project(owner: users(:standard_user2))

    submitted_state_project.transition_to!(workflow_states(:submitted))

    visit cas_approvals_projects_path

    within '#my_access_approvals' do
      assert has_content?(submitted_state_project.id.to_s)
      assert has_no_content?(draft_state_project.id.to_s)
    end
    # Doesn't have dataset approver grant so shouldn't see table
    assert has_no_css?('#my_dataset_approvals')
  end

  test 'users with both access and dataset approver roles should see both tables' do
    sign_in users(:cas_access_and_dataset_approver)

    visit cas_approvals_projects_path

    assert has_css?('#my_dataset_approvals')
    assert has_css?('#my_access_approvals')
  end
end
