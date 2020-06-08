# The allowed values for an xml_type
class EnumerationValue < ApplicationRecord
  belongs_to :xml_type
  has_many :enumeration_value_dataset_versions, dependent: :destroy
  has_many :dataset_versions, through: :enumeration_value_dataset_versions

  scope :for_version, lambda { |version|
    joins(:enumeration_value_dataset_versions).
      where(enumeration_value_dataset_versions: { dataset_version_id: version.id })
  }
end
