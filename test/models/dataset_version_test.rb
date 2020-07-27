require 'test_helper'
class DatasetVersionTest < ActiveSupport::TestCase
  def setup
    @dataset = Dataset.find_by(name: 'COSD')
    @dataset_version = @dataset.dataset_versions.new(semver_version: '10.0')
    @dataset_version.save!
    EnumerationValueDatasetVersion.create!(enumeration_value: EnumerationValue.find(1),
                                           dataset_version: @dataset_version)
    @version_entity = Nodes::Entity.new(name: 'COSD', min_occurs: 1, max_occurs: 1,
                                        description: @dataset.description, sort: 0,
                                        dataset_version: @dataset_version)
  end

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

  test 'enumeration values should be cloned' do
    data_item = Nodes::DataItem.new(name: 'test_item_name', min_occurs: 0,
                                    dataset_version: @dataset_version)
    @version_entity.child_nodes << data_item
    @version_entity.save!

    @dataset_version.clone_version('11.0')
    new_version = DatasetVersion.find_by(semver_version: '11.0')

    assert_equal new_version.enumeration_values, @dataset_version.enumeration_values
  end

  test 'cloning dataset_version expected DataItem node attributes cloned' do
    data_item = Nodes::DataItem.new(name: 'test_item_name', sort: 1, min_occurs: 0, max_occurs: 2,
                                    reference: 'test_reference', annotation: 'test_annotation',
                                    description: 'test_description', xml_type_id: 2,
                                    data_dictionary_element_id: 393,
                                    dataset_version: @dataset_version)
    @version_entity.child_nodes << data_item
    @version_entity.save!
    @dataset_version.clone_version('11.0')
    new_version = DatasetVersion.find_by(semver_version: '11.0')
    cloned_data_item = new_version.nodes.find_by(name: 'test_item_name')

    assert_equal cloned_data_item.type, data_item.type
    assert_equal cloned_data_item.xml_type_id, data_item.xml_type_id
    assert_equal cloned_data_item.min_occurs, data_item.min_occurs
    assert_equal cloned_data_item.max_occurs, data_item.max_occurs
    assert_equal cloned_data_item.data_dictionary_element_id, data_item.data_dictionary_element_id
    assert_equal cloned_data_item.reference, data_item.reference
    assert_equal cloned_data_item.annotation, data_item.annotation
    assert_equal cloned_data_item.description, data_item.description
    refute_equal cloned_data_item.dataset_version_id, data_item.dataset_version_id
    assert_equal cloned_data_item.dataset_version_id, new_version.id
  end

  test 'cloning dataset_version expected Choice node attributes cloned' do
    choice = Nodes::Choice.new(name: 'test_item_name', sort: 1, min_occurs: 1, max_occurs: 2,
                               reference: 'test_reference', annotation: 'test_annotation',
                               description: 'test_description', choice_type_id: 1,
                               dataset_version: @dataset_version)
    @version_entity.child_nodes << choice
    @version_entity.save!
    @dataset_version.clone_version('11.0')
    new_version = DatasetVersion.find_by(semver_version: '11.0')

    cloned_choice = new_version.nodes.find_by(name: 'test_item_name')

    assert_equal cloned_choice.type, choice.type
    assert_nil cloned_choice.xml_type_id, choice.xml_type_id
    assert_equal cloned_choice.min_occurs, choice.min_occurs
    assert_equal cloned_choice.max_occurs, choice.max_occurs
    assert_nil cloned_choice.data_dictionary_element_id, choice.data_dictionary_element_id
    assert_equal cloned_choice.choice_type_id, choice.choice_type_id
    assert_equal cloned_choice.reference, choice.reference
    assert_equal cloned_choice.annotation, choice.annotation
    assert_equal cloned_choice.description, choice.description
    refute_equal cloned_choice.dataset_version_id, choice.dataset_version_id
    assert_equal cloned_choice.dataset_version_id, new_version.id
  end

  test 'cloning dataset_version expected CategoryChoice node attributes cloned' do
    category_choice = Nodes::CategoryChoice.new(name: 'test_item_name', sort: 1, min_occurs: 1,
                                                reference: 'test_reference',
                                                annotation: 'test_annotation',
                                                description: 'test_description',
                                                dataset_version: @dataset_version)
    @version_entity.child_nodes << category_choice
    @version_entity.save!
    @dataset_version.clone_version('11.0')
    new_version = DatasetVersion.find_by(semver_version: '11.0')

    cloned_category_choice = new_version.nodes.find_by(name: 'test_item_name')

    assert_equal cloned_category_choice.type, category_choice.type
    assert_nil cloned_category_choice.xml_type_id, category_choice.xml_type_id
    assert_equal cloned_category_choice.min_occurs, category_choice.min_occurs
    assert_nil cloned_category_choice.max_occurs, category_choice.max_occurs
    assert_nil cloned_category_choice.data_dictionary_element_id, category_choice.data_dictionary_element_id
    assert_equal cloned_category_choice.reference, category_choice.reference
    assert_equal cloned_category_choice.annotation, category_choice.annotation
    assert_equal cloned_category_choice.description, category_choice.description
    refute_equal cloned_category_choice.dataset_version_id, category_choice.dataset_version_id
    assert_equal cloned_category_choice.dataset_version_id, new_version.id
  end

  test 'cloning dataset_version expected Group node attributes cloned' do
    group = Nodes::Group.new(name: 'test_item_name', sort: 0, reference: 'test_reference',
                             annotation: 'test_annotation', description: 'test_description',
                             dataset_version: @dataset_version)
    @version_entity.child_nodes << group
    @version_entity.save!
    @dataset_version.clone_version('11.0')
    new_version = DatasetVersion.find_by(semver_version: '11.0')

    cloned_group = new_version.nodes.find_by(name: 'test_item_name')

    assert_equal cloned_group.type, group.type
    assert_nil cloned_group.xml_type_id, group.xml_type_id
    assert_nil cloned_group.min_occurs, group.min_occurs
    assert_nil cloned_group.max_occurs, group.max_occurs
    assert_nil cloned_group.data_dictionary_element_id, group.data_dictionary_element_id
    assert_equal cloned_group.reference, group.reference
    assert_equal cloned_group.annotation, group.annotation
    assert_equal cloned_group.description, group.description
    refute_equal cloned_group.dataset_version_id, group.dataset_version_id
    assert_equal cloned_group.dataset_version_id, new_version.id
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
