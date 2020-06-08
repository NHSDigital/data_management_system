require 'test_helper'
class DatasetVersionTest < ActiveSupport::TestCase
  test 'version_entity' do
    assert DatasetVersion.find_by(semver_version: '8.2').version_entity.present?
    assert_equal 'COSD', DatasetVersion.find_by(semver_version: '8.2').version_entity.name
  end

  test 'to_xsd' do
    # to_xsd
  end

  test 'version_entity_xsd' do
    # version_entity_xsd
  end

  test 'build_common' do
    # build_common
  end

  test 'build_xsd_groups' do
    # build_xsd_groups
  end

  test 'build_xml_data_type_references' do
    # build_xml_data_type_references
  end

  test 'return header nodes if present' do
    assert dataset_version.header_nodes.present?
    assert sact_version.header_nodes.blank?
  end

  test 'clone_version' do
    dataset_version.clone_version('8.4')
    assert DatasetVersion.find_by(semver_version: '8.4').present?
    new_version = DatasetVersion.find_by(semver_version: '8.4')
    assert dataset_version.nodes.count == new_version.nodes.count
    assert dataset_version.categories.count == new_version.categories.count
  end

  test 'build_child' do
    new_node = Nodes::Entity.new(name: 'New Node')
    new_version = DatasetVersion.create!(dataset: Dataset.find_by(name: 'COSD'),
                                         semver_version: '8.4')
    dataset_version.build_child(new_node, imaging_node, dataset_version)
    assert new_node.child_nodes.present?
    assert_nil new_node.child_nodes.first.id
    assert_nil new_node.child_nodes.first.parent_id
    new_version.destroy
  end

  test 'build_node' do
    type = 'Nodes::DataItem'
    new_version = DatasetVersion.create!(dataset: Dataset.find_by(name: 'COSD'),
                                         semver_version: '8.4')
    new_node = dataset_version.build_node(type, cns_item, new_version)
    assert_nil new_node.id
    assert_nil new_node.parent_id
    assert new_node.type == cns_item.type
    assert new_node.name == cns_item.name
    assert new_node.reference == cns_item.reference
    assert new_node.annotation == cns_item.annotation
    assert new_node.description == cns_item.description
    assert new_node.xml_type_id == cns_item.xml_type_id
    assert new_node.choice_type_id == cns_item.choice_type_id
    assert new_node.sort == cns_item.sort
    assert_nil new_node.created_at
    assert_nil new_node.updated_at
    assert new_node.category_id == cns_item.category_id
    assert new_node.min_occurs == cns_item.min_occurs
    assert new_node.max_occurs == cns_item.max_occurs
    new_version.destroy
  end

  test 'build_node_categories' do
    new_node = Nodes::Entity.new(name: 'New Node')
    new_version = DatasetVersion.create!(dataset: Dataset.find_by(name: 'COSD'),
                                         semver_version: '8.4')
    new_category = Category.create!(dataset_version: new_version, name: 'CNS')
    dataset_version.build_node_categories(new_node, imaging_cns_node, new_version)
    assert_equal 1, new_node.categories.length
    assert_equal '8.4', new_node.categories.first.dataset_version.semver_version
    new_version.destroy
    new_category.destroy
  end

  test 'should not be able to create same version within a dataset' do
    new_version = DatasetVersion.new(semver_version: '8.2', dataset: Dataset.find_by(name: 'COSD'))
    refute new_version.valid?
    assert new_version.errors.messages.keys.include? :semver_version
    error_msg = 'Version already exists for dataset!'
    assert new_version.errors.messages[:semver_version].include? error_msg
  end

  test 'only one category per version can be designated as core' do
    new_version = DatasetVersion.new(semver_version: '8.5', dataset: Dataset.find_by(name: 'COSD'))
    %w[garfield arlene nermal].each do |name|
      new_version.categories.build(name: name, core: true)
    end

    refute new_version.valid?

    new_version.categories.first.core = false
    refute new_version.valid?

    new_version.categories.second.core = false
    assert new_version.valid?

    new_version.categories.last.core = false
    assert new_version.valid?
    refute new_version.valid?(:publish)

    new_version.categories.last.core = true
    assert new_version.valid?(:publish)    
  end

  test 'return core category for version if it exists' do
    dv = DatasetVersion.find_by(semver_version: '9.0', dataset_id: Dataset.find_by(name: 'COSD').id)
    
    assert dv.core_category.present?
    refute sact_version.core_category.present?
  end

  private

  def sact_version
    @sact_version ||= DatasetVersion.find_by(semver_version: '2.0',
                                             dataset_id: Dataset.find_by(name: 'SACT'))
  end

  def dataset_version
    DatasetVersion.find_by(semver_version: '8.2', dataset_id: Dataset.find_by(name: 'COSD').id)
  end

  def imaging_node
    @imaging_node ||= dataset_version.entities.find_by(name: 'Imaging')
  end

  def imaging_cns_node
    @imaging_cns_node ||= dataset_version.entities.find_by(name: 'ImagingCNS')
  end

  def cns_item
    @cns_item ||= dataset_version.nodes.find_by(name: 'ImagingGroup').data_items.first
  end
end
