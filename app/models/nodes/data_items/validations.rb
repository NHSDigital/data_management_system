module Nodes
  module DataItems
    module Validations
      extend ActiveSupport::Concern
      included do
        validates :description, presence: true, on: :publish
        validate :has_no_parent, on: :publish
        validate :must_have_data_dictionary_element_or_xml_type_for_schema_build, on: :publish

        def must_have_data_dictionary_element_or_xml_type_for_schema_build
          error_msg = 'item requires data dictionary element or xml type to build schema'
          errors.add(:node, error_msg) if data_dictionary_element.nil? && xml_type.nil?
        end

        def has_no_parent
          error_msg = 'Item has no parent'
          errors.add(:node, errors) if parent_id.nil?
        end
      end
    end
  end
end