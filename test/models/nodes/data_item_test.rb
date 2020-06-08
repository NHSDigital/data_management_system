require 'test_helper'
module Nodes
  class DataItemTest < ActiveSupport::TestCase
    test 'item_type' do
      assert_equal 'xs:date', date_item.item_type
      assert_nil code_item.item_type
    end

    test 'build attribute reference' do
      refute date_item.use_attribute_reference?
      assert code_item.use_attribute_reference?
    end

    test 'attribute xsd' do
      output = ''
      schema = empty_schema(output)
      code_item.attribute_reference(schema)
      assert_equal 4, output.lines.length
      assert output.lines.include? "<xs:complexType>\n"
      assert output.lines.include? "</xs:complexType>\n"
      att = "  <xs:attribute name=\"extension\" use=\"required\" " \
            "type=\"ST_NHS_OrganisationIdentifierCodeOne\"/>\n"
      assert output.lines.include? att
    end

    test 'generate xsd' do
      output = ''
      schema = empty_schema(output)
      date_item.to_xsd(schema)
      assert_equal 6, output.lines.length
      assert output.lines.include? "    <xs:appinfo>REPORTING PERIOD START DATE</xs:appinfo>\n"
      element = "<xs:element name=\"ReportingPeriodStartDate\" minOccurs=\"1\" " \
                "maxOccurs=\"1\" type=\"xs:date\">\n"
      assert output.lines.include? element
    end

    test 'element names' do
      assert_equal 'IContainSpaces', Nodes::DataItem.new(name: 'I CONTAIN SPACES').xsd_element_name
      assert_equal 'ContainPlus', Nodes::DataItem.new(name: 'CONTAIN + PLUS').xsd_element_name
      assert_equal 'Brackets', Nodes::DataItem.new(name: '(BRACKETS)').xsd_element_name
      assert_equal 'Allow-Hyphen', Nodes::DataItem.new(name: 'ALLOW - HYPHEN').xsd_element_name
      assert_equal 'RemoveForward', Nodes::DataItem.new(name: 'REMOVE / FORWARD').xsd_element_name
      assert_equal 'LowerCase', Nodes::DataItem.new(name: 'lower case').xsd_element_name
    end
  
    private

    def dataset_version
      DatasetVersion.find_by(semver_version: '8.2', dataset_id: Dataset.find_by(name: 'COSD').id)
    end

    def date_item
      @date_item ||= dataset_version.data_items.find_by(name: 'REPORTING PERIOD START DATE')
    end

    def code_item
      @code_item ||=
        dataset_version.data_items.find_by(name: 'ORGANISATION IDENTIFIER CODE OF PROVIDER')
    end
  end
end
