require 'test_helper'
class XmlTypeTest < ActiveSupport::TestCase
  test 'reference_xsd_type_directly' do
    assert phe_date.reference_xsd_type_directly?
    assert yes_no_not_applicable.reference_xsd_type_directly?
  end

  test 'build xml date element' do
    output = ''
    schema = empty_schema(output)
    phe_date.standard_element(schema)
    assert_equal 3, output.lines.length
    restriction_tag_open = "<xs:restriction base=\"xs:date\">\n"
    restriction_tag_close = "</xs:restriction>\n"
    assert output.lines.include? restriction_tag_open
    assert output.lines.include? restriction_tag_close
  end

  test 'build xml string element' do
    output = ''
    schema = empty_schema(output)
    phe_string.standard_element(schema)
    assert_equal 5, output.lines.length
    restriction_tag_open = "<xs:restriction base=\"xs:string\">\n"
    restriction_tag_close = "</xs:restriction>\n"
    min_tag = "  <xs:minLength value=\"44\"/>\n"
    max_tag = "  <xs:maxLength value=\"55\"/>\n"
    assert output.lines.include? restriction_tag_open
    assert output.lines.include? restriction_tag_close
    assert output.lines.include? min_tag
    assert output.lines.include? max_tag
  end

  test 'build xml value element' do
    output = ''
    schema = empty_schema(output)
    phe_value.standard_element(schema)
    assert_equal 5, output.lines.length
    restriction_tag_open = "<xs:restriction base=\"xs:integer\">\n"
    restriction_tag_close = "</xs:restriction>\n"
    min_tag = "  <xs:minInclusive value=\"44\"/>\n"
    max_tag = "  <xs:maxInclusive value=\"55\"/>\n"
    assert output.lines.include? restriction_tag_open
    assert output.lines.include? restriction_tag_close
    assert output.lines.include? min_tag
    assert output.lines.include? max_tag
  end

  test 'build xml decimal element with restrictions' do
    output = ''
    schema = empty_schema(output)
    decimal_item.standard_element(schema)
    assert_equal 7, output.lines.length
    assert output.lines.any?("  <xs:fractionDigits value=\"3\"/>\n")
  end

  test 'xsd generation with enumeration values' do
    output = ''
    schema = empty_schema(output)
    yes_no_not_applicable.element_with_values(schema, dataset_version)
    assert_equal 18, output.lines.length
  end

  test 'xml type xsd with enumeration values' do
    output = ''
    schema = empty_schema(output)
    yes_no_not_applicable.to_xsd(schema, dataset_version)
    assert_equal 20, output.lines.length
    assert output.lines.include? "<xs:simpleType name=\"ST_NHS_YesNoNotApplicable\">\n"
    assert output.lines.include? "</xs:simpleType>\n"
  end

  test 'xml type xsd without enumeration values' do
    output = ''
    schema = empty_schema(output)
    phe_value.to_xsd(schema, dataset_version)
    assert_equal 7, output.lines.length
    assert output.lines.include? "<xs:simpleType name=\"MadeUpCNSSpecificValueItem\">\n"
    assert output.lines.include? "</xs:simpleType>\n"
  end

  test 'min_size_tag returns correct value' do
    x = XmlType.new(name: 'min_size_tag_test', restriction: 'xs:string', min_length: 1)
    assert_equal :minLength, x.min_size_tag
    x = XmlType.new(name: 'min_size_tag_test', restriction: 'xs:token', min_length: 1)
    assert_equal :minLength, x.min_size_tag
    x = XmlType.new(name: 'min_size_tag_test', restriction: 'xs:integer', min_length: 1)
    assert_equal :minInclusive, x.min_size_tag
    x = XmlType.new(name: 'min_size_tag_test', restriction: 'xs:decimal', min_length: 1)
    assert_equal :minInclusive, x.min_size_tag
  end

  test 'max_size_tag returns correct value' do
    x = XmlType.new(name: 'max_size_tag_test', restriction: 'xs:string', max_length: 2)
    assert_equal :maxLength, x.max_size_tag
    x = XmlType.new(name: 'max_size_tag_test', restriction: 'xs:token', max_length: 2)
    assert_equal :maxLength, x.max_size_tag
    x = XmlType.new(name: 'max_size_tag_test', restriction: 'xs:integer', max_length: 1)
    assert_equal :maxInclusive, x.max_size_tag
    x = XmlType.new(name: 'max_size_tag_test', restriction: 'xs:decimal', max_length: 1)
    assert_equal :maxInclusive, x.max_size_tag
  end

  test 'min_value returns correct value' do
    x = XmlType.new(name: 'min_value_tag_test', restriction: 'xs:string', min_length: 1)
    assert_equal 1, x.min_value
    x = XmlType.new(name: 'min_value_tag_test', restriction: 'xs:token', min_length: 1)
    assert_equal 1, x.min_value
    x = XmlType.new(name: 'min_value_tag_test', restriction: 'xs:integer', min_length: 1)
    assert_equal 1, x.min_value
    x = XmlType.new(name: 'min_value_tag_test', restriction: 'xs:decimal', min_length: 0.9)
    assert_equal 0.9, x.min_value
  end

  test 'max_value returns correct value' do
    x = XmlType.new(name: 'max_value_tag_test', restriction: 'xs:string', max_length: 1)
    assert_equal 1, x.max_value
    x = XmlType.new(name: 'max_value_tag_test', restriction: 'xs:token', max_length: 1)
    assert_equal 1, x.max_value
    x = XmlType.new(name: 'max_value_tag_test', restriction: 'xs:integer', max_length: 1)
    assert_equal 1, x.max_value
    x = XmlType.new(name: 'max_value_tag_test', restriction: 'xs:decimal', max_length: 0.9)
    assert_equal 0.9, x.max_value
  end

  test 'national_code returns expected value' do
    assert_nil phe_string.doc_national_code
    assert_equal '44.0 - 55.5', decimal_item.doc_national_code
  end

  test 'format returns expected value' do
    assert_equal 'Min an44 Max an55', phe_string.doc_format
    assert_equal 'an1', yes_no_not_applicable.doc_format
  end

  test 'sample date value' do
    x = create(name: 'date', restriction: 'xs:date')
    dummy_data = x.send(:sample_data)
    assert dummy_data =~ /\A[0-9]{4}-[0-9]{2}-[0-9]{2}\Z/
  end

  test 'sample datetime value' do
    x = create(name: 'datetime', restriction: 'xs:dateTime')
    dummy_data = x.send(:sample_data)
    assert dummy_data =~ /\A[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}\Z/
  end

  test 'sample string value' do
    x = create(name: 'string', restriction: 'xs:string')
    dummy_data = x.send(:sample_data)
    assert dummy_data.length.between?(min_length, max_length)
  end

  test 'sample integer value' do
    x = create(name: 'integer', restriction: 'xs:integer')
    assert x.send(:sample_data).between?(min_length, max_length)
  end

  test 'sample restricted decimal value' do
    x = create(name: 'decimal', restriction: 'xs:decimal', fractiondigits: 2, totaldigits: 6)
    dummy_data = x.send(:sample_data)
    assert dummy_data.between?(min_length, max_length)
  end

  test 'sample digit restricted decimal value' do
    x = create(name: 'decimal', restriction: 'xs:decimal', fractiondigits: 2, totaldigits: 6,
               min_length: nil, max_length: nil)
    dummy_data = x.send(:sample_data)
    assert dummy_data.between?(0, 9999.99)
  end

  test 'validate xml_attribute_value_included_in_all_attribute_list' do
    x = XmlType.new(name: 'test')
    x.xml_attribute_for_value = XmlAttribute.first
    refute x.valid?
    assert x.errors.messages[:xml_type].present?
    assert x.errors.messages[:xml_type].include? 'Xml attribute value not in available list'
  end

  test 'only enumeration values valid for version are available for selection' do
    assert_equal 3, yes_no_not_applicable.available_values_for_version(dataset_version).length
    version_eight_two =
      Dataset.find_by(name: 'COSD').dataset_versions.find_by(semver_version: '8.2')
    assert_equal 3, yes_no_not_applicable.available_values_for_version(version_eight_two).length
  end

  private

  def min_length
    100
  end

  def max_length
    1000
  end

  def create(options)
    default_options = { min_length: min_length, max_length: max_length }
    XmlType.new(default_options.merge(options))
  end

  def phe_date
    @phe_date ||= XmlType.find_by(name: 'xs:date')
  end

  def phe_string
    @phe_string ||= XmlType.find_by(name: 'MadeUpCNSSpecificStringItem')
  end

  def phe_value
    @phe_value ||= XmlType.find_by(name: 'MadeUpCNSSpecificValueItem')
  end

  def yes_no_not_applicable
    @yes_no_not_applicable ||= XmlType.find_by(name: 'ST_NHS_YesNoNotApplicable')
  end

  def decimal_item
    @decimal_item ||= XmlType.find_by(name: 'MadeUpDecimalItem')
  end

  def dataset_version
    @dataset_version ||=
      Dataset.find_by(name: 'COSD').dataset_versions.find_by(semver_version: '8.2')
  end
end
