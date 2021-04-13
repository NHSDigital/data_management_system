# Add missing MBIS Node and change description on a couple of others
class AddUpdateMbisNodes < ActiveRecord::Migration[6.0]
  def up
    Nodes::DataItem.create!(
      dataset_version: Dataset.find_by(name: 'MBIS').
                       dataset_versions.find_by(semver_version: '7.1'),
      parent_node: Dataset.find_by(name: 'MBIS').
                   dataset_versions.find_by(semver_version: '7.1').nodes.
                   find_by(name: 'Registration', type: 'Nodes::Group'),
      name: 'dor', description: 'Date of registration', sort: 1, min_occurs: 1, max_occurs: 1,
      governance: Governance.find_by(value: 'NON IDENTIFYING DATA'), field_name: 'REG_DATE',
      field_type: 'character varying'
    )

    Nodes::DataItemGroup.find_by(
      name: 'ICDPVF',
      dataset_version: Dataset.find_by(name: 'MBIS').
                       dataset_versions.find_by(semver_version: '7.1')
    ).update(description: 'Final ICD10 code stillbirths only')

    Nodes::DataItemGroup.find_by(
      name: 'ICDPV',
      dataset_version: Dataset.find_by(name: 'MBIS').
                       dataset_versions.find_by(semver_version: '7.1')
    ).update(description: 'ICD10 code Stillbirths only')
  end

  def down
    Nodes::DataItem.find_by(
      name: 'dor', description: 'Date of registration',
      dataset_version: Dataset.find_by(name: 'MBIS').
      dataset_versions.find_by(semver_version: '7.1')
    ).destroy

    Nodes::DataItemGroup.find_by(
      name: 'ICDPVF',
      dataset_version: Dataset.find_by(name: 'MBIS').
                       dataset_versions.find_by(semver_version: '7.1')
    ).update(description: 'ICD10 code Stillbirths only')

    Nodes::DataItemGroup.find_by(
      name: 'ICDPV',
      dataset_version: Dataset.find_by(name: 'MBIS').
                       dataset_versions.find_by(semver_version: '7.1')
    ).update(description: 'Final ICD10 code stillbirths only')
  end
end
