module Xsd
  module ConstituentParts
    # builds the master file for a schema version
    class Master
      include Nodes::Utility
      include Xsd::Generator
      include Xsd::Header

      attr_accessor :schema, :zipfile, :dataset, :dataset_version,
                    :semver_version, :dataset_name, :version_entity

      def initialize(version, zipfile = nil)
        @schema = Builder::XmlMarkup.new(target: '', indent: 2)
        schema.instruct!
        @dataset_version = version
        @dataset = version.dataset
        @semver_version = version.schema_version_format
        @dataset_name = dataset.name
        @version_entity = version.version_entity
        @zipfile = zipfile

        build
      end

      # build master XSD file
      def build
        schema.xs :schema, ns('xs', :w3, :schema, true) do |schema_|
          included_file_xsd(schema_)
          version_entity_xsd_file(schema_)
          build_record_parents(schema_)
        end
      end

      def included_file_xsd(schema)
        all_xsd_files.each { |f| xsd_include_schema(schema, f) }
      end

      # return a list of file names we'll be splitting out to
      def all_xsd_files
        data_types_fname = "#{dataset_name}-v#{semver_version}_DATA_TYPES.xsd"
        child_record_entity_names =
          dataset_version.immediate_child_entities_of_record.map(&:name).map { |e| xsd_file_name(e) }
        all_names = [data_types_fname] + child_record_entity_names
        return all_names if dataset_version.categories.blank?

        category_names = (dataset_version.categories - [dataset_version.core_category]).pluck(:name)
        category_file_names = category_names.map { |c| xsd_file_name(c) }
        all_names + category_file_names
      end

      # Build the master parent entity
      def version_entity_xsd_file(schema)
        # build differently with groups from Record entity down tree
        build_element(schema, :element, name: version_entity.name, type: version_entity.name)
        # Ignore entity's items, we'll build a xsd group of them later
        version_entity.build_generic(schema)
      end

      def build_record_parents(schema)
        entity_file_list = dataset_version.first_level_of_version_child_entities +
                             [dataset_version.version_entity]
        entity_file_list.each do |entity|
          entity.complex_entity(schema, true)
          entity.child_nodes.groups.each do |group|
            group.to_xsd_groups(schema)
          end
        end
      end

      def save_file
        filename = "schema/#{dataset_name}-v#{semver_version}.xsd"
        save_schema_pack_file(schema.target!, filename, zipfile)
      end
    end
  end
end
