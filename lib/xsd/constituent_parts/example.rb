module Xsd
  module ConstituentParts
    # builds full xml examples for schema version
    class Example
      include Nodes::Utility
      include Xsd::Generator
      include Xsd::Header

      attr_accessor :xml, :zipfile, :dataset_version, :semver_version, :dataset_name,
                    :version_entity, :sample_type

      def initialize(version, sample_type, zipfile = nil)
        @dataset_version = version
        @dataset_name = version.name
        @semver_version = version.schema_version_format
        @version_entity = version.version_entity
        @zipfile = zipfile
        @sample_type = sample_type

        @xml = build
      end

      W3_ORG = 'http://www.w3.org/2001/XMLSchema-instance'.freeze
      DATA_DICTIONARY = 'http://www.datadictionary.nhs.uk/messages/'.freeze

      def build
        Nokogiri::XML::Builder.new do |xml|
          xml.comment 'System Generated'
          sample_msg = 'Contains a example Record of each category if applicable'
          xml.comment sample_msg if contains_category_choice?
          xml.send(dataset_version.header_one, 'xmlns:xsi' => W3_ORG,
                   dataset_version.header_three => dataset_version.header_four) do
            # Temporarily set the namespace to nil so that child nodes do not use it
            parent_namespace = xml.parent.namespace
            xml.parent.namespace = nil
            send(sample_type, xml)
            # restore the parent namespace.
            xml.parent.namespace = parent_namespace
          end
        end
      end

      def contains_category_choice?
        dataset_version.nodes.map(&:type).include? 'Nodes::CategoryChoice'
      end

      def sample_items(xml)
        version_entity.child_nodes.sort_by(&:sort).each do |node|
          node.to_xml(xml)
        end
      end

      def sample_choices(xml)
        version_entity.child_nodes.sort_by(&:sort).each do |node|
          node.to_xml_choice(xml: xml)
        end
      end

      def save_file
        filename = "sample_xml/#{dataset_name}-v#{semver_version}_#{sample_type}.xml"
        save_schema_pack_file(xml.to_xml, filename, zipfile)
      end
    end
  end
end
