# Model for NHS data dictionary
class DataDictionaryElement < ApplicationRecord
  has_many :data_items, class_name: 'Nodes::DataItem', dependent: :destroy,
                        inverse_of: :data_dictionary_element
  belongs_to :xml_type, optional: true

  # Remove spaces and replace any opening bracket with an underscore
  def xsd_element_name
    element_name = name.gsub('(', '_ ')
    element_name.delete!(')', '')
    element_name = element_name.split(' ').map(&:capitalize)
    element_name.join
  end
end
