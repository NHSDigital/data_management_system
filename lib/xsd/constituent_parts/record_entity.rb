module Xsd
  module ConstituentParts
    # builds xsd for immediate child entities of Record for a schema version
    class RecordEntity
      include Nodes::Utility
      include Xsd::Generator
      include Xsd::Header

      attr_accessor :schema, :zipfile, :semver_version,
                    :dataset_name, :entity

      def initialize(entity, zipfile = nil)
        @schema = Builder::XmlMarkup.new(target: '', indent: 2)
        schema.instruct!
        @entity = entity
        @dataset_name = entity.dataset.name
        @semver_version = entity.dataset_version.schema_version_format
        @zipfile = zipfile

        build
      end

      # Record entities.
      def build
        schema.xs :schema, ns('xs', :w3, :schema, false) do |schema_|
          entity_and_children_xsd(entity, schema_)
        end
      end

      # Loop through and build all children of record entities
      def entity_and_children_xsd(node, schema)
        node.complex_entity(schema, true) if node.entity?
        node.to_xsd_groups(schema) if node.group?
        node.child_nodes.each do |child_node|
          entity_and_children_xsd(child_node, schema)
        end
      end

      def save_file
        filename = "schema/#{dataset_name}-v#{semver_version}_#{entity.name.upcase}.xsd"
        save_schema_pack_file(schema.target!, filename, zipfile)
      end
    end
  end
end
