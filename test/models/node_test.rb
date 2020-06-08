require 'test_helper'
class NodeTest < ActiveSupport::TestCase
  test 'xsd element name' do
    n = Nodes::DataItem.create!(name: 'Linkage patient Id', min_occurs: 0,
                                description: 'item description')
    assert_equal 'LinkagePatientId', n.xsd_element_name
    n = Nodes::DataItem.find_by(name: 'Linkage patient Id')
    dde = DataDictionaryElement.create!(name: 'LINKAGE PATIENT ID')
    n.data_dictionary_element = dde
    n.name = nil
    n.save!
    assert_equal 'LinkagePatientId', n.xsd_element_name
  end

  test 'correct xsd type generated' do
    # Imaging has child nodes specific to CNS
    assert_equal 'CNSImaging', imaging_node.xsd_type_name('CNS')
    # Imaging has no child nodes specific to Breast
    assert_equal 'Imaging', imaging_node.xsd_type_name('Breast')
  end

  test 'cached name returned' do
    assert_equal 'Imaging', imaging_node.xsd_name(:type_name)
    assert_equal 'CNSImaging', imaging_node.xsd_name(:type_name, 'CNS')
  end

  test 'build a complex entity if relevant for category' do
    assert imaging_node.build_entity?('CNS')
    refute imaging_node.build_entity?('Breast')
    refute imaging_cns_node.build_entity?('CNS')
  end

  test 'entity nodes for category' do
    assert imaging_node.node_for_category?('Breast')
    assert imaging_node.node_for_category?('CNS')
    refute imaging_cns_node.node_for_category?('Breast')
    assert imaging_cns_node.node_for_category?('CNS')
  end

  test 'data item nodes for category' do
    refute imaging_cns_node.node_for_category?('Breast')
    assert imaging_cns_node.node_for_category?('CNS')
  end

  test 'entity or item node belongs to category' do
    refute imaging_node.belongs_to_category?('CNS')
    refute imaging_node.belongs_to_category?('Breast')
    assert imaging_cns_node.belongs_to_category?('CNS')
    refute imaging_cns_node.belongs_to_category?('Breast')
  end

  test 'find parent node for a data item node' do
    refute cns_item.parent_entity_belongs_to_category?('Breast')
    assert cns_item.parent_entity_belongs_to_category?('CNS')
  end

  test 'entity node belongs to all categories' do
    assert imaging_node.belongs_to_all_categories?
    refute imaging_cns_node.belongs_to_all_categories?
  end

  test 'specific_to' do
    refute imaging_node.contains_child_nodes_specific_to?('Breast')
    assert imaging_node.contains_child_nodes_specific_to?('CNS')
    # deeper branch
    refute treatment_node.contains_child_nodes_specific_to?('Breast')
    assert treatment_node.contains_child_nodes_specific_to?('CNS')
  end

  test 'max_occurrences' do
    assert_equal 'unbounded', Node.find_by(name: 'RecordGroupChoice').max_occurrences
    assert_equal 1, Node.find_by(name: 'LinkagePatientId').max_occurrences
  end

  test 'parent_node_for_description' do
    assert_nil cosd_nine.nodes.find_by(name: 'COSD').parent_node_for_description

    assert_equal cosd_nine.nodes.find_by(name: 'RecordGroupChoice'),
                 cosd_nine.nodes.find_by(name: 'Record').parent_node_for_description
  end

  test 'excel_occurrence_text' do
    cosd = Dataset.find_by(name: 'COSD').dataset_versions.find_by(semver_version: '9.0')

    assert_equal 'Must be one occurrence per Record (1..1)',
                 cosd.nodes.find_by(name: 'LinkagePatientId').excel_occurrence_text
    assert_equal 'Must be at least 1 occurrence(s) per COSD (1..*)',
                 cosd.nodes.find_by(name: 'RecordGroupChoice').excel_occurrence_text
    assert_equal 'Must be one occurrence per LinkagePatientId (1..1)',
                 cosd.nodes.find_by(name: 'PERSON BIRTH DATE').excel_occurrence_text
    assert_equal 'May be multiple occurrences per DiagnosisAdditionalItems (0..*)',
                 cosd.nodes.find_by(name: 'SECONDARY DIAGNOSIS (ICD)').excel_occurrence_text
  end

  test 'min_occurs must not be nil for node' do
    new_node = Nodes::DataItem.new(name: 'test', description: 'item description')
    refute new_node.valid?
    error_msg = 'Minimum occurrences cannot be nil for this node'
    assert new_node.errors.messages[:node].any? error_msg
    new_node.min_occurs = 0
    assert new_node.valid?
  end

  test 'complex_entity builds valid XSD' do
    output = ''
    schema = empty_schema(output)
    imaging_node.complex_entity(schema, false)
    assert_equal 6, output.lines.length
    assert output.lines.include? "<xs:complexType name=\"Imaging\">\n"
    assert output.lines.include? "  <xs:sequence>\n"
    assert output.lines.include? "    <xs:group ref=\"ImagingGroup\"/>\n"
    assert output.lines.include? "  </xs:sequence>\n"
    assert output.lines.include? "</xs:complexType>\n"
  end

  test 'parent entity in tree' do
    entity = Nodes::Entity.new(name: 'ParentNode', min_occurs: 0)
    group =  Nodes::Group.new(name: 'Group')
    child_entity = Nodes::Entity.new(name: 'ChildEntity', min_occurs: 0)
    item = Nodes::DataItem.new(name: 'Item', min_occurs: 0, description: 'item description')
    child_entity.child_nodes << item
    group.child_nodes << child_entity
    entity.child_nodes << group
    entity.save!
    entity.reload
    item.parent_entity_in_tree == entity
  end

  test 'cannot add entity with same level at the same level in tree' do
    parent_entity = dataset_version.nodes.find_by(name: 'Record')
    # persisted entry is still valid
    assert parent_entity.child_nodes.find_by(name: 'LinkagePatientId').valid?
    new_entity = Nodes::Entity.new(name: 'LinkagePatientId', min_occurs: 0)
    new_entity.parent_node = parent_entity
    refute new_entity.valid?
    expected_msg = 'Another entity already exists with this name: LinkagePatientId, ' \
                   'type: Nodes::Entity at this level'
    assert new_entity.errors.messages[:node].any? expected_msg
    new_entity.name = 'LinkagePatientIdDifferent'
    assert new_entity.valid?
  end

  test 'data item uses data dictionary xml type if present' do
    dde = DataDictionaryElement.new(name: 'TEST DICTIONARY ELEMENT')
    dde.xml_type = XmlType.first
    dde.save!
    item = Nodes::DataItem.new(name: 'TestXmlItem', min_occurs: 0, max_occurs: 1,
                               description: 'item description')
    item.data_dictionary_element = dde.reload
    item.save!
    assert_equal item.xmltype, XmlType.first
  end

  # originall in the data_source_item/data_items controller test
  test 'should not be able to delete data source items currently in use' do
    assert_no_difference 'Nodes::DataItem.count' do
      node = Dataset.find_by(name: 'Births Gold Standard').dataset_versions.
             last.data_items.find_by(name: 'DOB')
      node.destroy
    end
  end

  test 'in_child_path_for' do
    options = { min_occurs: 0, max_occurs: 1, description: 'test' }
    parent = Nodes::Entity.create!(options.merge(name: 'Parent'))
    c_one = Nodes::Entity.create!(options.merge(name: 'ChildOne', parent_id: parent.id))
    c_two = Nodes::Entity.create!(options.merge(name: 'ChildTwo', parent_id: c_one.id))
    c_three = Nodes::Entity.create!(options.merge(name: 'ChildThree', parent_id: c_two.id))
    
    assert c_one.in_child_path_for?(parent)
    assert c_two.in_child_path_for?(parent)
    assert c_three.in_child_path_for?(parent)

    # node not child of above parent
    c_other = Nodes::Entity.create!(options.merge(name: 'OtherChild'))
    refute c_other.in_child_path_for?(parent)
  end

  test 'node_categories' do
    options = { min_occurs: 0, max_occurs: 1, description: 'test' }
    parent = Nodes::Entity.new(options.merge(name: 'Parent'))
    parent.categories << Category.first
    parent.save!
    c_one = Nodes::Entity.create!(options.merge(name: 'ChildOne', parent_id: parent.id))
    assert [Category.first], c_one.node_categories
  end

  test 'parent_choices_to_get_to_this_choice' do
    options = { min_occurs: 0, description: 'test' }
    record = Nodes::Entity.create!(options.merge(name: 'Record'))
    parent_choice = Nodes::Choice.new(options.merge(name: 'Parent', parent_id: record.id))
    parent_choice.choice_type = ChoiceType.find_by(name: 'optional_or')
    parent_choice.save!
    c_one = Nodes::Entity.create!(options.merge(name: 'ChildOne', parent_id: parent_choice.id))
    c_two = Nodes::Entity.create!(options.merge(name: 'ChildTwo', parent_id: parent_choice.id))
    c_three = Nodes::Choice.new(options.merge(name: 'ChildChoice', parent_id: c_two.id))
    c_three.choice_type = ChoiceType.find_by(name: 'optional_or')
    c_three.save!
    expected = { parent_choice.id => c_two.id }
    actual = c_three.parent_choices_to_get_to_this_choice
    assert actual, expected
  end

  private

  def dataset_version
    DatasetVersion.find_by(semver_version: '8.2', dataset_id: Dataset.find_by(name: 'COSD').id)
  end

  def imaging_node
    @imaging_node ||= Nodes::Entity.find_by(name: 'Imaging', dataset_version: dataset_version)
  end

  def imaging_cns_node
    @imaging_cns_node ||= dataset_version.entities.find_by(name: 'ImagingCNS')
  end

  def cns_item
    @cns_item ||= imaging_cns_node.child_nodes.first
  end

  def treatment_node
    @treatment_node ||= Nodes::Entity.find_by(name: 'Treatment', dataset_version: dataset_version)
  end

  def cosd_nine
    @cosd_nine ||= Dataset.find_by(name: 'COSD').dataset_versions.find_by(semver_version: '9.0')
  end
end
