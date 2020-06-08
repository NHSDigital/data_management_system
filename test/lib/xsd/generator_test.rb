require 'test_helper'

# Test valid xsd is built
module Xsd
  class GeneratorTest < ActionDispatch::IntegrationTest
    test 'build xsd element' do
      return unless RUN_SCHEMA_TESTS
      output = ''
      schema = empty_schema(output)

      item = 'ItemNameOne'
      options = { name: item, minOccurs: 0, maxOccurs: 1, type: "#{item}Type" }
      generator.build_element(schema, :simpleType, options)
      assert output.include? '<xs:simpleType'
      assert output.include? 'minOccurs="0"'
      assert output.include? 'maxOccurs="1"'
      assert output.include? 'type="ItemNameOneType"'
      assert output.include? '<xs:simpleType name="ItemNameOne" minOccurs="0" maxOccurs="1" '\
                             'type="ItemNameOneType"'
    end

    test 'build xsd element no options' do
      return unless RUN_SCHEMA_TESTS
      output = ''
      schema = empty_schema(output)

      generator.build_element(schema, :simpleType)
      assert output.include? '<xs:simpleType/>'
    end

    test 'build xsd group' do
      return unless RUN_SCHEMA_TESTS
      output = ''
      schema = empty_schema(output)

      generator.xsd_group(schema, 'MadeUpGroupName')
      assert output.include? '<xs:group name="MadeUpGroupName"/>'

      # with block
      output = ''
      schema = empty_schema(output)

      generator.xsd_group(schema, 'MadeUpGroupName') do |group|
        generator.xsd_sequence(group)
      end
      assert output.include? '<xs:group name="MadeUpGroupName">'
      assert output.include? '<xs:sequence/>'
      assert output.include? '</xs:group>'
    end

    test 'build xsd sequence' do
      return unless RUN_SCHEMA_TESTS
      output = ''
      schema = empty_schema(output)

      generator.xsd_sequence(schema)
      assert output.include? '<xs:sequence/>'

      # with block
      output = ''
      schema = empty_schema(output)

      options = { name: 'ItemName', minOccurs: 0, maxOccurs: 1, type: 'ItemNameType' }
      generator.xsd_sequence(schema) do |sequence|
        generator.build_element(sequence, :element, options)
      end

      assert output.include? '<xs:sequence>'
      assert output.include? '<xs:element name="ItemName" minOccurs="0" maxOccurs="1" '\
                             'type="ItemNameType"/>'
      assert output.include? '</xs:sequence>'
    end

    test 'build xsd restriction' do
      return unless RUN_SCHEMA_TESTS
      output = ''
      schema = empty_schema(output)

      generator.xsd_restriction(schema, 'test')
      assert output.include? '<xs:restriction base="test"/>'
    end

    test 'build xsd attribute' do
      return unless RUN_SCHEMA_TESTS
      output = ''
      schema = empty_schema(output)

      generator.xsd_attribute(schema, name: 'Test', type: 'TestType')
      assert output.include? '<xs:attribute name="Test" type="TestType"/>'
    end

    test 'build simple type' do
      return unless RUN_SCHEMA_TESTS
      output = ''
      schema = empty_schema(output)

      generator.xsd_simple_type(schema, 'Test')
      assert output.include? '<xs:simpleType name="Test"/>'
    end

    test 'build complex type' do
      return unless RUN_SCHEMA_TESTS
      output = ''
      schema = empty_schema(output)

      generator.xsd_complex_type(schema, 'Test')
      assert output.include? '<xs:complexType name="Test"/>'
    end

    test 'build complex type tag' do
      return unless RUN_SCHEMA_TESTS
      output = ''
      schema = empty_schema(output)

      generator.xsd_complex_type_tag(schema) do
        # build empty element
      end
      assert output.include? '<xs:complexType>'
      assert output.include? '</xs:complexType>'
    end

    test 'build complex content' do
      return unless RUN_SCHEMA_TESTS
      output = ''
      schema = empty_schema(output)

      generator.xsd_complex_content(schema) do
        # build empty element
      end
      assert output.include? '<xs:complexContent>'
      assert output.include? '</xs:complexContent>'
    end

    test 'build annotation' do
      return unless RUN_SCHEMA_TESTS
      output = ''
      schema = empty_schema(output)
      annotation = 'Bob Loblaw wrote some annotation text for this'
      generator.xsd_annotation(schema, annotation)

      assert output.include? '<xs:annotation>'
      assert output.include? "<xs:appinfo>#{annotation}</xs:appinfo>"
      assert output.include? '</xs:annotation>'
    end

    test 'build enumeration value' do
      return unless RUN_SCHEMA_TESTS
      output = ''
      schema = empty_schema(output)

      generator.xsd_enumeration_value(schema, 'TestValue')
      assert output.include? '<xs:enumeration value="TestValue"/>'

      # with annotation
      output = ''
      schema = empty_schema(output)

      annotation = 'Bob Loblaw wrote some annotation text for this'
      generator.xsd_enumeration_value(schema, 'TestValue') do |enumeration|
        generator.xsd_annotation(enumeration, annotation)
      end
      assert output.include? '<xs:enumeration value="TestValue">'
      assert output.include? '<xs:annotation>'
      assert output.include? "<xs:appinfo>#{annotation}</xs:appinfo>"
      assert output.include? '</xs:annotation>'
      assert output.include? '</xs:enumeration>'
    end

    test 'build include schema' do
      return unless RUN_SCHEMA_TESTS
      output = ''
      schema = empty_schema(output)

      generator.xsd_include_schema(schema, 'IncludeMeInYourSchema.xsd')
      assert output.include? '<xs:include schemaLocation="IncludeMeInYourSchema.xsd"/>'
    end

    def empty_schema(output)
      schema = ::Builder::XmlMarkup.new(target: output, indent: 2)
      schema.instruct!
      schema
    end

    def generator
      Node.first
    end
  end
end
