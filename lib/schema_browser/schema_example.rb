module SchemaBrowser
  # Build schema examples
  class SchemaExample
    include Nodes::Utility
    include Xsd::Header

    attr_accessor :zipfile, :xsd, :node, :category_name, :version,
                  :semver_version, :filename, :dataset_name

    def initialize(zipfile, parent_category_choice, node, filename, category_name = nil)
      @zipfile = zipfile
      @xsd = ::Builder::XmlMarkup.new(target: '', indent: 2)
      @xsd.instruct!
      @depth = 0
      @index = false
      @node = node
      @category_name = category_name
      @version = node.dataset_version
      @semver_version = version.schema_version_format
      @filename = filename
      @dataset_name = version.name

      parent_category_choice ? build_category_choice_children : build
    end

    def build
      xsd.xs :schema, ns('xs', :w3, :schema, false) do
        if node.entity? && node.categories.present?
          node_with_categories
        elsif node.entity?
          node.complex_entity(xsd, true, category_name)
        elsif node.group?
          node.to_xsd_groups(xsd)
        end
      end
    end

    def node_with_categories
      node.categories.sort_by(&:sort).pluck(:name).each do |node_category_name|
        node.complex_entity(xsd, true, node_category_name)
      end
    end

    def build_category_choice_children
      xsd.xs :schema, ns('xs', :w3, :schema, false) do
        if category_name == version.core_category.name
          node.complex_entity(xsd, false, category_name)
        else
          node.build(xsd, category_name)
        end
      end
    end

    def save_file
      fname = "schema_browser/Schemas/#{filename}.xsd"
      save_schema_pack_file(xsd.target!, fname, zipfile)
    end
  end
end
