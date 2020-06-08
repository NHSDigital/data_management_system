# Definition of Xml Type that a data item can belong to
class XmlType < ApplicationRecord
  include Xsd::Generator

  has_many :data_items, class_name: 'Nodes::DataItem', dependent: :destroy, inverse_of: :xml_type
  has_many :data_dictionary_element, dependent: :destroy, inverse_of: :xml_type
  has_many :enumeration_values, dependent: :destroy
  has_many :xml_type_xml_attributes, dependent: :destroy, inverse_of: :xml_type
  has_many :xml_attributes, through: :xml_type_xml_attributes
  # Identify the attribute that some items will store a value in
  # Sticking with NHS convention of storing some values as a attribute
  # NHS Digital used attributes do store data
  # code      => lookups
  # extension => halfway house
  # value     => for nearly everything else
  belongs_to :xml_attribute_for_value, class_name: 'XmlAttribute',
                                       foreign_key: :xml_attribute_for_value_id,
                                       optional: true
  before_save :set_min_length_to_zero

  validate :xml_attribute_value_included_in_all_attribute_list

  def set_min_length_to_zero
    self.min_length = 0 if min_length.nil? && max_length.present?
  end

  # Sticking to NHS convention some data values are stored as attribute values.
  # An Element can have many attributes, so we need to ensure we are putting data in the correct
  # attribute when building examples
  # We need to ensure that attribute is part of the entire attribute list
  def xml_attribute_value_included_in_all_attribute_list
    return if xml_attribute_for_value.nil?
    errors.add(:xml_type, 'Xml attribute value not in available list') unless
      xml_attributes.include? xml_attribute_for_value
  end

  DEFAULT_XS_STANDARD_TYPES = %w[xs:date xs:dateTime].freeze

  INCLUSIVE_TAG_TYPES = %w[xs:integer xs:decimal].freeze

  # in XSD we want e.g minLength value="1" instead of minLength value="1.0"
  LENGTH_TAG_TYPES = %w[xs:string xs:token xs:integer].freeze

  DOC_DATE_FORMAT = 'an10 CCYY-MM-DD'.freeze

  DOC_DATETIME_FORMAT = 'an19 CCYY-MM-DDThh:mm:ss'.freeze

  def to_xsd(schema, dataset_version)
    xsd_simple_type(schema, name) do |simple_type|
      xsd_annotation(simple_type, annotation) if annotation.present?
      if enumeration_values.empty?
        standard_element(schema)
        next
      else
        element_with_values(schema, dataset_version)
      end
    end
  end

  # Attempt to just have elements directly reference a type if it has no other extra restrictions
  def reference_xsd_type_directly?
    (enumeration_values.blank? && xml_attributes.blank?) || (name != restriction)
  end

  def standard_element(schema)
    xsd_restriction(schema, restriction) do |restriction_tag|
      restriction_tag.xs :pattern, value: pattern if pattern.present?
      restriction_tag.xs min_size_tag, value: min_value if min_length.present?
      restriction_tag.xs max_size_tag, value: max_value if max_length.present?
      restriction_tag.xs :fractionDigits, value: fractiondigits if
        decimal_restrictions?(:fractiondigits)
      restriction_tag.xs :totalDigits, value: totaldigits if decimal_restrictions?(:totaldigits)
    end
  end

  def decimal_restrictions?(dim)
    restriction == 'xs:decimal' && send(dim).present?
  end

  def min_size_tag
    INCLUSIVE_TAG_TYPES.any?(restriction) ? :minInclusive : :minLength
  end

  def max_size_tag
    INCLUSIVE_TAG_TYPES.any?(restriction) ? :maxInclusive : :maxLength
  end

  def min_value
    LENGTH_TAG_TYPES.any?(restriction) ? min_length.to_i : min_length
  end

  def max_value
    LENGTH_TAG_TYPES.any?(restriction) ? max_length.to_i : max_length
  end

  def element_with_values(schema, dataset_version)
    xsd_restriction(schema, restriction) do |restriction|
      enumeration_values.sort_by(&:sort).each do |ev|
        next unless ev.dataset_versions.include? dataset_version
        xsd_enumeration_value(restriction, ev.enumeration_value) do |e_v|
          xsd_annotation(e_v, ev.annotation)
        end
      end
    end
  end

  def build_xsd?
    DEFAULT_XS_STANDARD_TYPES.exclude? name
  end

  def doc_format
    return DOC_DATE_FORMAT if date_type?
    return DOC_DATETIME_FORMAT if datetime_type?
    return string_format(:an) if string_type?
    return integer_format(:n) if integer_type?
    return decimal_format if decimal_type?
    return token_format if token_type?
  end

  # will return a single value if there are no enumeration values for the xml_type
  def doc_national_code
    # Use in existing excel document seems a bit random
    return if enumeration_values.present?
    return if min_length.nil? && max_length.nil?
    return "#{min_length} - #{max_length}" if decimal_type?
    return "#{min_length.to_i} - #{max_length.to_i}" if integer_type?
  end

  def available_values_for_version(version)
    enumeration_values.reject do |ev|
      ev.dataset_versions.exclude? version
    end
  end

  def xml_attribute_value_name
    xml_attribute_for_value&.name
  end

  private

  def string_format(type)
    return if min_length.nil? && max_length.nil?
    min = "Min #{type}#{min_length.to_i}"
    max = "Max #{type}#{max_length.to_i}"
    min_max_format(min, max)
  end

  def integer_format(type)
    return if min_length.nil? && max_length.nil?
    min = "Min #{type}#{min_length.to_i.to_s.length}"
    max = "Max #{type}#{max_length.to_i.to_s.length}"
    min_max_format(min, max)
  end

  def min_max_format(min, max)
    return max if min_length.positive? && min_length == max_length
    return max if min_length.zero? && max_length.positive?
    return min + ' ' + max if min_length && max_length
    return min if min_length
  end

  def decimal_format
    "n#{totaldigits - fractiondigits}.n#{fractiondigits}"
  end

  def token_format
    return string_format(:an) if enumeration_values.blank?
    max_ev_length = enumeration_values.map { |ev| ev.enumeration_value.length }.uniq.max
    "an#{max_ev_length}"
  end

  def date_type?
    restriction == 'xs:date'
  end

  def datetime_type?
    restriction == 'xs:dateTime'
  end

  def string_type?
    restriction == 'xs:string'
  end

  def integer_type?
    restriction == 'xs:integer'
  end

  def decimal_type?
    restriction == 'xs:decimal'
  end

  def token_type?
    restriction == 'xs:token'
  end

  def sample_data(version = nil)
    return random_date if date_type?
    return random_datetime if datetime_type?
    return random_string_pattern if pattern.present?
    return random_number.to_i if integer_type?
    return random_number.to_f.round(fractiondigits) if decimal_restricted?
    return decimal_min_max_length if decimal_type?
    return enumeration_choice(version) if token_type? && enumeration_values.present?
    return random_string if string_type? || token_type?
  end

  def random_date
    Date.current.strftime('%Y-%m-%d')
  end

  def random_datetime
    Time.zone.now.strftime('%Y-%m-%dT%H:%M:%S')
  end

  def random_string_pattern
    regex = Regexp.new(pattern)
    regex.random_example
  end

  def random_number
    return max_length if name == 'NHSNumber'
    SecureRandom.random_number(min_length..max_length)
  end

  def random_string
    # limit very long strings
    if max_length.present?
      limited_length = max_length > 100 ? 100 : max_length.to_i
      return SecureRandom.alphanumeric(limited_length)
    end
    SecureRandom.alphanumeric(min_length.to_i)
  end

  def decimal_min_max_length
    return unless min_length.nil? && max_length.nil?
    max_one = '9' * (totaldigits - fractiondigits)
    max_two = '9' * fractiondigits
    limit = "#{max_one}.#{max_two}"
    SecureRandom.random_number(0..limit.to_f).round(fractiondigits)
  end

  # a decimal which must be a range other than e.g 0 to 99.9
  def decimal_restricted?
    decimal_type? && min_length.present? && max_length.present?
  end

  # Only choose an option that is valid for the dataset version
  def enumeration_choice(version)
    available_values_for_version(version).map(&:enumeration_value).sample
  end
end
