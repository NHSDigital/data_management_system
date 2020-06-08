# Has many through for xml attributes
class XmlTypeXmlAttribute < ApplicationRecord
  belongs_to :xml_type
  belongs_to :xml_attribute
end
