module Xsd
  module ConstituentParts
    # Builds category specific schema components
    class Category
      include Nodes::Utility
      include Xsd::Generator
      include Xsd::Header

      attr_accessor :schema, :zipfile, :dataset_version, :semver_version, :dataset_name, :category

      def initialize(category, zipfile = nil)
        @schema = Builder::XmlMarkup.new(target: '', indent: 2)
        schema.instruct!
        @dataset_version = category.dataset_version
        @dataset_name = dataset_version.name
        @semver_version = dataset_version.schema_version_format
        @zipfile = zipfile
        @category = category

        build
      end

      def build
        # OTHER contains CORE sections and will have no specific sections
        return if category == dataset_version.core_category

        xsd_category(category.name)
      end

      def xsd_category(category)
        # Assuming only one Nodes::Category per version
        category_choice_node = dataset_version.preloaded_descendants.find(&:category_choice?)
        schema.xs :schema, ns('xs', :w3, :schema, true) do |schema_|
          category_choice_node.build_category(schema_, category)
        end
      end

      def save_file
        filename = "schema/#{dataset_name}-v#{semver_version}_#{category.name.upcase}.xsd"
        save_schema_pack_file(schema.target!, filename, zipfile)
      end
    end
  end
end
