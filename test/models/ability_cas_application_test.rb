require 'test_helper'

class AbilityCasApplicationTest < ActiveSupport::TestCase
  test 'basic dms user ability' do
    applicant = create_user(username: 'basic-user', email: 'bu@phe.gov.uk',
                            first_name: 'basic', last_name: 'user')

    not_owner_project = create_project(project_type: project_types(:cas),
                                       owner: users(:standard_user))
    owner_project = create_project(project_type: project_types(:cas), owner: applicant)
    owner_project.reload.current_state

    dataset = Dataset.find_by(name: 'Extra CAS Dataset One')
    project_dataset1 = ProjectDataset.new(dataset: dataset, terms_accepted: true, approved: false)
    project_dataset2 = ProjectDataset.new(dataset: dataset, terms_accepted: true, approved: false)

    not_owner_project.project_datasets << project_dataset1
    owner_project.project_datasets << project_dataset2

    applicant_ablity = Ability.new(applicant)

    assert applicant_ablity.can? :create, Project.new(project_type: project_types(:cas))
    # Should be able to read, update and destroy but only at DRAFT state
    assert applicant_ablity.can? :read, owner_project
    assert applicant_ablity.can? :update, owner_project
    assert applicant_ablity.can? :destroy, owner_project
    assert applicant_ablity.can? :reapply, owner_project.project_datasets.last
    # Can't do any crud on other users projects
    refute applicant_ablity.can? :destroy, not_owner_project
    refute applicant_ablity.can? :read, not_owner_project
    refute applicant_ablity.can? :update, not_owner_project
    refute applicant_ablity.can? :reapply, not_owner_project.project_datasets.last

    owner_project.transition_to!(workflow_states(:submitted))
    owner_project.reload.current_state

    # Should only be able to read own project and reapply for dataset after DRAFT
    assert applicant_ablity.can? :read, owner_project
    refute applicant_ablity.can? :update, owner_project
    refute applicant_ablity.can? :destroy, owner_project
    assert applicant_ablity.can? :reapply, owner_project.project_datasets.last
  end

  test 'cas_dataset_approver ability' do
    applicant = create_user(username: 'casdataset-approver', email: 'cda@phe.gov.uk',
                            first_name: 'cas', last_name: 'dataset-approver')

    matched_dataset_project = create_project(project_type: project_types(:cas),
                                             owner: users(:standard_user))
    owner_project = create_project(project_type: project_types(:cas), owner: applicant)
    owner_project.reload.current_state
    non_matched_dataset_project = create_project(project_type: project_types(:cas),
                                                 owner: users(:standard_user))
    non_cas_project = create_project(project_type: project_types(:eoi), project_purpose: 'test',
                                     owner: users(:standard_user))

    dataset = Dataset.find_by(name: 'Extra CAS Dataset One')
    project_dataset = ProjectDataset.new(dataset: dataset, terms_accepted: true)
    matched_dataset_project.project_datasets << project_dataset

    Grant.create(dataset: dataset, roleable: DatasetRole.fetch(:approver), user: applicant).tap(&:save)
    applicant_ablity = Ability.new(applicant)

    assert applicant_ablity.can? :create, Project.new(project_type: project_types(:cas))
    assert applicant_ablity.can? :read, owner_project
    assert applicant_ablity.can? :update, owner_project
    assert applicant_ablity.can? :destroy, owner_project

    # Cannot do when at DRAFT state
    refute applicant_ablity.can? :destroy, matched_dataset_project
    refute applicant_ablity.can? :read, matched_dataset_project
    refute applicant_ablity.can? :update, matched_dataset_project
    refute applicant_ablity.can? :update, project_dataset

    matched_dataset_project.transition_to(Workflow::State.find('SUBMITTED'))
    matched_dataset_project.reload_current_state
    applicant_ablity = Ability.new(applicant)

    refute applicant_ablity.can? :destroy, matched_dataset_project
    assert applicant_ablity.can? :read, matched_dataset_project
    refute applicant_ablity.can? :update, matched_dataset_project
    assert applicant_ablity.can? :update, project_dataset

    project_dataset.update(approved: true)
    matched_dataset_project.transition_to(Workflow::State.find('ACCESS_APPROVER_APPROVED'))
    applicant_ablity = Ability.new(applicant)

    # Check still able to read project and edit projectdataset after approved is no longer nil
    refute applicant_ablity.can? :destroy, matched_dataset_project
    assert applicant_ablity.can? :read, matched_dataset_project
    refute applicant_ablity.can? :update, matched_dataset_project
    assert applicant_ablity.can? :update, project_dataset
    # Shouldn't be able to access a project that doesn't require their dataset
    refute applicant_ablity.can? :destroy, non_matched_dataset_project
    refute applicant_ablity.can? :read, non_matched_dataset_project
    refute applicant_ablity.can? :update, non_matched_dataset_project
    refute applicant_ablity.can? :update, non_matched_dataset_project.project_datasets.first
    # Shouldn't be able to crud non-cas projects where they aren't owner
    refute applicant_ablity.can? :destroy, non_cas_project
    refute applicant_ablity.can? :read, non_cas_project
    refute applicant_ablity.can? :update, non_cas_project
    refute applicant_ablity.can? :update, non_cas_project.project_datasets.first
  end

  test 'cas_access_approver ability' do
    applicant = create_user(username: 'casaccess-approver', email: 'caa@phe.gov.uk',
                            first_name: 'cas', last_name: 'dataset-approver')

    not_owner_project = create_project(project_type: project_types(:cas), owner: users(:standard_user))
    owner_project = create_project(project_type: project_types(:cas), owner: applicant)
    owner_project.reload.current_state
    non_cas_project = create_project(project_type: project_types(:eoi), project_purpose: 'test',
                                     owner: users(:standard_user))

    Grant.create(roleable: SystemRole.fetch(:cas_access_approver), user: applicant).tap(&:save)

    applicant_ablity = Ability.new(applicant)

    # Should be able to crud their own created batch
    assert applicant_ablity.can? :create, Project.new(project_type: project_types(:cas))
    assert applicant_ablity.can? :read, owner_project
    assert applicant_ablity.can? :update, owner_project
    assert applicant_ablity.can? :destroy, owner_project
    # Should only be able to read cas projects at Submitted state
    refute applicant_ablity.can? :destroy, not_owner_project
    refute applicant_ablity.can? :read, not_owner_project
    refute applicant_ablity.can? :update, not_owner_project
    # Should not be do any crud on non-cas projects
    refute applicant_ablity.can? :destroy, non_cas_project
    refute applicant_ablity.can? :read, non_cas_project
    refute applicant_ablity.can? :update, non_cas_project

    not_owner_project.transition_to(Workflow::State.find('SUBMITTED'))
    applicant_ablity = Ability.new(applicant)

    # Should be able to read cas projects at Submitted state
    refute applicant_ablity.can? :destroy, not_owner_project
    assert applicant_ablity.can? :read, not_owner_project
    refute applicant_ablity.can? :update, not_owner_project
  end

  test 'cas_manager ability' do
    applicant = create_user(username: 'casmanager', email: 'cm@phe.gov.uk',
                            first_name: 'cas', last_name: 'manager')

    not_owner_project = create_project(project_type: project_types(:cas), owner: users(:standard_user))
    owner_project = create_project(project_type: project_types(:cas), owner: applicant)
    owner_project.reload.current_state
    non_cas_project = create_project(project_type: project_types(:eoi), project_purpose: 'test',
                                     owner: users(:standard_user))

    Grant.create(roleable: SystemRole.fetch(:cas_manager), user: applicant).tap(&:save)

    applicant_ablity = Ability.new(applicant)

    # Should be able to crud their own created batch
    assert applicant_ablity.can? :create, Project.new(project_type: project_types(:cas))
    assert applicant_ablity.can? :read, owner_project
    assert applicant_ablity.can? :update, owner_project
    assert applicant_ablity.can? :destroy, owner_project
    # Should only be able to read cas projects
    refute applicant_ablity.can? :destroy, not_owner_project
    assert applicant_ablity.can? :read, not_owner_project
    refute applicant_ablity.can? :update, not_owner_project
    # Should not be do any crud on non-cas projects
    refute applicant_ablity.can? :destroy, non_cas_project
    refute applicant_ablity.can? :read, non_cas_project
    refute applicant_ablity.can? :update, non_cas_project
  end
end
