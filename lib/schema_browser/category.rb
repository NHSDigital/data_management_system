module SchemaBrowser
  # version category pages
  class Category
    include Nodes::Utility
    include SchemaBrowser::Utility
    include SchemaBrowser::UtilityCategory
    attr_accessor :zipfile, :html, :dataset, :version, :category_name

    def initialize(zipfile, version, category_name)
      @zipfile = zipfile
      @html = ''
      @depth = 0
      @index = false
      @version = version
      @dataset = version.dataset
      @category_name = category_name

      build
    end

    def build
      tag(:html) do
        head_common
        body_common do
          body_container_common do
            navbar
            category_content(category_name)
          end
        end
      end
    end

    def save_file
      save_schema_pack_file(html, "schema_browser/Categories/#{category_name}.html", zipfile)
    end
  end
end
