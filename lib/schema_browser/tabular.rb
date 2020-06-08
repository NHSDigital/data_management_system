module SchemaBrowser
  # Produce tabular displays of Nodes
  class Tabular
    include Nodes::Utility
    include SchemaBrowser::Utility
    attr_accessor :zipfile, :html, :node, :dataset, :version, :filename, :category_name

    def initialize(zipfile, node, filename, category_name = nil)
      @zipfile = zipfile
      @html = ''
      @depth = 0
      @index = false
      @node = node
      @dataset = node.dataset_version.dataset
      @version = node.dataset_version
      @filename = filename
      @category_name = category_name

      build
    end

    def build
      tag(:html) do
        head_common
        body_common do
          body_container_common do
            navbar
            tabular
          end
        end
      end
    end

    def tabular
      tag(:div, id: 'content', class: 'row') do
        tag(:div, class: 'span12') do
          node_name =
            category_name.nil? ? node.xsd_element_name : category_name + node.xsd_element_name
          tag(:h3) do
            content("#{node_name} Descriptions")
          end
          tag(:br) do
            parent_name = if node.parent_node&.parent_node&.category_choice?
                            "{Category}#{node.parent_node&.name}"
                          else
                            node.parent_node&.name
                          end
            content("Parent Class: #{parent_name}")
          end
          choice_comment
          table_tabular
        end
      end
    end

    def choice_comment
      return unless node.choice? || node.category_choice?

      tag(:br) do
        content(node.send(:choice_text))
      end
    end

    def table_tabular
      tag(:table, class: 'table table-striped') do
        tag(:thead) do
          tag(:tr) do
            tag(:th, width: '15%')
            tag(:th, style: 'vertical-align: top', width: '55%')
            tag(:th, style: 'vertical-align: top', width: '40%')
          end
        end
        if node.category_choice?
          tabular_category_choice_body
        else
          tabular_node_body
        end
      end
    end

    def tabular_category_choice_body
      tag(:tbody) do
        node.child_nodes.sort_by(&:sort).each do |child_node|
          version.categories.sort_by(&:sort).pluck(:name).each do |category_name|
            tabular_row(child_node, category_name)
          end
        end
      end
    end

    def tabular_node_body
      tag(:tbody) do
        node.child_nodes.sort_by(&:sort).each do |child_node|
          if node.parent_node&.category_choice?
            next unless child_node.node_for_category?(category_name) || child_node.category_choice?
          end
          tabular_row(child_node)
        end
      end
    end

    def tabular_row(child_node)
      tag(:tr) do
        if child_node.data_item?
          tabular_data_item(child_node)
        else
          tabular_non_data_item(child_node)
        end
        node_info(child_node)
      end
    end

    def node_info(child_node)
      tag(:td, style: 'vertical-align: top') do
        if child_node.data_item?
          content(child_node.annotation)
        else
          tag(:a, href: "#{path}/Tabular/#{child_node.xsd_element_name}.html") do
            content('Expand')
          end
        end
      end
    end

    def tabular_data_item(child_node)
      tag(:td, style: 'text-align: right; vertical-align: top') do
        content('Element Name: ')
        ['Occurrences: ', 'Type: '].each do |att|
          tag(:br) do
            content(att)
          end
        end
      end
      tag(:td, style: 'vertical-align: top') do
        content(child_node.xsd_element_name)
        tag(:br) do
          content("[#{multiplicity(child_node)}]")
        end
        tag(:br) do
          tag(:a, href: "#{path}/DataTypes.html##{child_node.xmltype.name}") do
            content(child_node.xmltype.name)
          end
        end
      end
    end

    # other nodes should drill down
    def tabular_non_data_item(child_node)
      # For category choices
      node_name = category_node_name(child_node)
      tag(:td, style: 'text-align: right; vertical-align: top') do
        content('Element Name: ')
        tag(:br) do
          content('Occurrences: ')
        end
      end
      tag(:td, style: 'vertical-align: top') do
        tag(:a, href: "#{path}/Tabular/#{node_name}.html") do
          content(node_name)
        end
        tag(:br) do
          content("[#{multiplicity(child_node)}]")
          content('(Choice)') if child_node.category_choice? || child_node.choice?
        end
      end
    end

    def category_node_name(child_node)
      if node.category_choice? && category_name
        category_name + child_node.xsd_element_name
      else
        child_node.xsd_element_name
      end
    end

    def save_file
      save_schema_pack_file(html, "schema_browser/Tabular/#{filename}.html", zipfile)
    end
  end
end
