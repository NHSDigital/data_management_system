module SchemaBrowser
  # Build Category Choice nodes if applicable
  class CategoryChoice
    include Nodes::Utility
    include SchemaBrowser::Utility
    include SchemaBrowser::UtilityCategory
    attr_accessor :zipfile, :html, :node, :dataset, :version

    def initialize(zipfile, node)
      @zipfile = zipfile
      @html = ''
      @depth = 0
      @index = false
      @node = node
      @version = node.dataset_version
      @dataset = version.dataset

      build
    end

    def build
      tag(:html) do
        head_common
        body_common do
          body_container_common do
            navbar
            category_choice_content
          end
        end
      end
    end

    def category_choice_content
      tag(:div, id: 'content', class: 'row') do
        tag(:div, class: 'span12') do
          category_table do
            node.child_nodes.sort_by(&:sort).each do |child_node|
              version.categories.sort_by(&:sort).pluck(:name).each do |category_name|
                table_row_category("#{category_name}#{child_node.xsd_element_name}")
              end
            end
          end
        end
      end
      tag(:div, id: 'push')
    end

    def save_file
      filename = "schema_browser/Tabular/#{node.xsd_element_name}.html"
      save_schema_pack_file(html, filename, zipfile)
    end
  end
end
