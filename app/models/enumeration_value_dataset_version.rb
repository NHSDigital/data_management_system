# To enable us to allow correct values in a schema when new values for an xml_type change
class EnumerationValueDatasetVersion < ApplicationRecord
  belongs_to :enumeration_value
  belongs_to :dataset_version
end