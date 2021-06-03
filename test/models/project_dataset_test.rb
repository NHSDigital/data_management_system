require 'test_helper'

class ProjectDatasetTest < ActiveSupport::TestCase
  test 'Only unique datasets allowed' do
    project = build_project
    dataset = Dataset.find_by(name: 'Deaths Gold Standard')
    project_dataset = ProjectDataset.new(dataset: dataset)
    project.project_datasets << project_dataset
    project.project_datasets << project_dataset
    refute project.valid?
  end

  test 'dataset_approval scope should only return to user with correct grant' do
    project = create_cas_project(owner: users(:standard_user2))
    project_dataset = ProjectDataset.new(dataset: Dataset.find_by(name: 'Extra CAS Dataset One'))
    project.project_datasets << project_dataset
    pdl = ProjectDatasetLevel.new(access_level_id: 1, expiry_date: Time.zone.today + 1.week)
    project_dataset.project_dataset_levels << pdl

    assert_equal 0, ProjectDataset.dataset_approval(users(:standard_user2)).count

    assert_equal 1, ProjectDataset.dataset_approval(users(:cas_dataset_approver)).count

    grant = Grant.where(user_id: users(:cas_dataset_approver).id).first
    grant.dataset_id = 84
    grant.save!

    assert_equal 0, ProjectDataset.dataset_approval(users(:cas_dataset_approver)).count
  end

  test 'dataset_approval scope should return all datasets for that user by default' do
    project = create_cas_project(owner: users(:standard_user2))
    project_dataset = ProjectDataset.new(dataset: Dataset.find_by(name: 'Extra CAS Dataset One'))
    project.project_datasets << project_dataset
    pdl = ProjectDatasetLevel.new(access_level_id: 1, expiry_date: Time.zone.today + 1.week,
                                  approved: nil)
    project_dataset.project_dataset_levels << pdl

    assert_equal 1, ProjectDataset.dataset_approval(users(:cas_dataset_approver)).count

    pdl.approved = true
    pdl.save!

    assert_equal 1, ProjectDataset.dataset_approval(users(:cas_dataset_approver)).count

    pdl.approved = true
    pdl.save!

    assert_equal 1, ProjectDataset.dataset_approval(users(:cas_dataset_approver)).count
  end

  test 'dataset_approval scope should only return approved status is nil if passed that argument' do
    project = create_cas_project(owner: users(:standard_user2))
    project_dataset = ProjectDataset.new(dataset: Dataset.find_by(name: 'Extra CAS Dataset One'))
    project.project_datasets << project_dataset
    pdl = ProjectDatasetLevel.new(access_level_id: 1, expiry_date: Time.zone.today + 1.week,
                                  approved: nil)
    project_dataset.project_dataset_levels << pdl

    assert_equal 1, ProjectDataset.dataset_approval(users(:cas_dataset_approver), [nil]).count

    pdl.approved = true
    pdl.save!

    assert_equal 0, ProjectDataset.dataset_approval(users(:cas_dataset_approver), [nil]).count
  end

  test 'destroy_project_dataset_levels_without_selected before_save callback' do
    project = create_cas_project(owner: users(:standard_user2))
    project_dataset = ProjectDataset.new(dataset: dataset(83), terms_accepted: true)
    project.project_datasets << project_dataset
    pdl1 = ProjectDatasetLevel.new(access_level_id: 1, expiry_date: Time.zone.today, selected: true)
    pdl2 = ProjectDatasetLevel.new(access_level_id: 2, expiry_date: Time.zone.today,
                                   selected: false)
    project_dataset.project_dataset_levels << pdl1
    project_dataset.project_dataset_levels << pdl2
    project_dataset.save!

    assert pdl1.persisted?
    refute pdl2.persisted?
    assert project_dataset.project_dataset_levels.include? pdl1
    refute project_dataset.project_dataset_levels.include? pdl2
  end
end
