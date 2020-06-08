# Allow multiple attributes for a xsd schema element
class XmlAttribute < ApplicationRecord
  has_many :xml_type_xml_attributes, dependent: :destroy
  has_many :xml_types, through: :xml_type_xml_attributes

  DB_TO_XSD_FIELD_MAPPING = { attribute_id: :id }.freeze

  ATTRIBUTES_FOR_XSD = %i[default fixed form attribute_id name ref type use].freeze

  def attributes_for_xsd
    ATTRIBUTES_FOR_XSD.each_with_object({}) do |field, attrs|
      next if send(field).nil?
      attrs[DB_TO_XSD_FIELD_MAPPING[field] || field] = send(field)
    end
  end
end
