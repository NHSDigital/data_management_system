# Currently XML and Non XML => Logical
# Table Specification type should be used for ODR/MBIS applicationos
class DatasetType < ApplicationRecord
  has_many :datasets

  def self.fetch(key)
    return key if key.is_a?(self)

    @dataset_types ||= {
      xml:        unscoped.where(name: 'xml').first!,
      non_xml:    unscoped.where(name: 'non_xml').first!,
      table_spec: unscoped.where(name: 'table_specification').first!,
      odr: unscoped.where(name: 'odr').first!,
      cas: unscoped.where(name: 'cas').first!
    }

    @dataset_types.fetch(key)
  end
end
