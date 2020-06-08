module SchemaBrowser
  # Generate Index page
  class Index
    include Nodes::Utility
    include SchemaBrowser::Utility
    attr_accessor :zipfile, :html, :dataset, :version

    def initialize(zipfile, version)
      @zipfile = zipfile
      @html = ''
      @depth = 0
      @index = true
      @version = version
      @dataset = version.dataset

      build
    end

    def build
      tag(:html) do
        head_common
        body_common do
          body_container_common do
            navbar
            about
          end
        end
      end
    end

    def save_file
      save_schema_pack_file(html, 'schema_browser/Index.html', zipfile)
    end
  end
end
