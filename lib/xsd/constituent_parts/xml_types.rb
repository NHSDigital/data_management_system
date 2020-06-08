module Xsd
  module ConstituentParts
    # builds the Xml Types file for a schema version
    class XmlTypes
      include Nodes::Utility
      include Xsd::Generator
      include Xsd::Header

      attr_accessor :schema, :zipfile, :dataset_version, :semver_version, :dataset_name

      def initialize(version, zipfile = nil)
        @schema = Builder::XmlMarkup.new(target: '', indent: 2)
        schema.instruct!
        @dataset_version = version
        @dataset_name = version.name
        @semver_version = version.schema_version_format
        @zipfile = zipfile

        build
      end

      # build xml data types
      def build
        schema.xs :schema, ns('xs', :w3, :schema, false) do |schema_|
          dataset_version.build_xml_data_type_references(schema_)
        end
      end

      def save_file
        filename = "schema/#{dataset_name}-v#{semver_version}_DATA_TYPES.xsd"
        save_schema_pack_file(schema.target!, filename, zipfile)
      end
    end
  end
end
