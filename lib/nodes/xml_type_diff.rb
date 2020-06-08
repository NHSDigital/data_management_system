module Nodes
  # methods for building xml type diff information
  module XmlTypeDiff
    # First thing list all new XmlTypes used in dataset. (for v8 to v9 this will be everything)
    # Diff task for v9 to future v10 should handle XmlType changes
    # TODO: changes. fron v8 - v9 everything will be new but going forwards there will be diffs
    def xml_type_changes(new_version, old_version)
      latest_xml_types = new_version.send(:xml_types_for_version)
      previous_xml_types = old_version.send(:xml_types_for_version)
      @txt << "XML TYPE CHANGES\n\n"
      (latest_xml_types - previous_xml_types).each do |xml_type|
        xml_type_detail(xml_type, new_version)
      end
    end

    def xml_type_detail(xml_type, version)
      xml_keys = XmlType.attribute_names - XML_TYPE_IGNORED_FIELDS
      details = xml_keys.each_with_object({}) do |key, xml_attrs|
        xml_attrs[key] = xml_type.send(key) unless xml_type.send(key).nil?
      end
      if xml_type.xml_attribute_for_value
        details['attribute_for_value'] = xml_type.xml_attribute_for_value&.name
        details['attribute_use'] = xml_type.xml_attribute_for_value&.use
      end
      if xml_type.enumeration_values.present?
        details['enumeration_values'] =
          xml_type.enumeration_values.for_version(version).sort_by(&:sort).
          map(&:enumeration_value).join(', ')
      end
      print_doc_format(details)
    end

    def print_doc_format(details)
      @txt << "***CREATE XMLTYPE***\n\n"
      details.each do |k, v|
        @txt << "#{k.humanize} #{' ' * (xml_type_spacing - k.length)}=> #{v}\n"
      end
      @txt << "\n"
    end

    def xml_type_spacing
      @xml_type_spacing ||=
        (XmlType.attribute_names - XML_TYPE_IGNORED_FIELDS + %w[attribute_for_value attribute_use]).
        map(&:length).max
    end
  end
end
