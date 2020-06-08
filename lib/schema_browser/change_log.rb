module SchemaBrowser
  # Generate the change log and create a page for it
  class ChangeLog
    include Nodes::Utility
    include SchemaBrowser::Utility
    attr_accessor :zipfile, :html, :dataset, :version, :version_previous, :filename

    def initialize(zipfile, version, version_previous, filename)
      @zipfile = zipfile
      @html = ''
      @depth = 0
      @index = true
      @version = version
      @version_previous = version_previous
      @dataset = version.dataset
      @filename = filename

      build
    end

    def build
      change_log = Nodes::ChangeLog.new(dataset, version_previous, version, false) unless
        version_previous.nil?
      tag(:html) do
        head_common
        body_common do
          body_container_common do
            navbar
            tag(:pre) do
              text = version_previous.nil? ? 'No Previous Version' : change_log.txt
              html << text
            end
          end
        end
      end
    end

    def save_file
      save_schema_pack_file(html, "schema_browser/#{filename}.html", zipfile)
    end
  end
end
