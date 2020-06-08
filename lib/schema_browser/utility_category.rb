module SchemaBrowser
  # shared methods
  module UtilityCategory
    def category_content(category_name)
      tag(:div, id: 'content', class: 'row') do
        tag(:div, class: 'span12') do
          category_table do
            entities_for_category(category_name).each do |cat_entity|
              table_row_category(cat_entity.xsd_element_name)
            end
          end
        end
      end
      tag(:div, id: 'push')
    end

    def category_table(&block)
      tag(:table, class: 'table table-striped') do
        tag(:thead) do
          tag(:th, width: '60%')
          tag(:th, width: '10%', style: 'text-align: center') { content('Model') }
          tag(:th, width: '10%', style: 'text-align: center') { content('Tabular') }
          tag(:th, width: '10%', style: 'text-align: center') { content('Schema') }
          tag(:th, width: '10%', style: 'text-align: center') { content('Example') }
        end
        tag(:tbody) do
          block.call if block_given?
        end
      end
    end

    def table_row_category(node_name)
      tag(:tr) do
        col_one(node_name)
        col_two(node_name)
        col_three(node_name)
        col_four(node_name)
        col_five(node_name)
      end
    end

    # col 1 Description
    def col_one(node_name)
      tag(:td, width: '60%', style: 'text-align: left; vertical-align: middle') do
        tag(:b) do
          content(node_name)
        end
        tag(:br) do
          text = "This model is a representation of the COSD #{node_name} from the Data " \
                 'Dictionary.'
          content(text)
        end
      end
    end

    # col 2 Model
    def col_two(node_name)
      tag(:td, style: 'text-align: center; vertical-align: middle') do
        tag(:a, title: 'Model', href: "../Models/#{node_name}.html") do
          tag(:span, class: 'label label-info') do
            content('View')
          end
        end
      end
    end

    # col 3 Tabular
    def col_three(node_name)
      tag(:td, style: 'text-align: center; vertical-align: middle') do
        tag(:a, title: 'Tabular View', href: "../Tabular/#{node_name}.html") do
          tag(:span, class: 'label label-info') do
            content('View')
          end
        end
      end
    end

    # col 4 Schema
    def col_four(node_name)
      tag(:td, style: 'text-align: center; vertical-align: middle') do
        tag(:a, title: 'Schema', href: "../Schemas/#{node_name}.xsd") do
          tag(:span, class: 'label label-info') do
            content('View')
          end
        end
      end
    end

    # col 5 Example
    def col_five(node_name)
      tag(:td, style: 'text-align: center; vertical-align: middle') do
        tag(:a, title: 'Example', href: "../Examples/#{node_name}.xml") do
          tag(:span, class: 'label label-info') do
            content('View')
          end
        end
      end
    end

    # return entities in dataset that belong to a category and not core
    # retain sort
    def entities_for_category(category_name)
      collect_entities(for_cat = [], version.version_entity, category_name)
      for_cat
    end

    def collect_entities(collection, node, category_name)
      node.child_nodes.sort_by(&:sort).each do |child_node|
        collection << child_node if
          child_node.entity? && child_node.belongs_to_category?(category_name)
        collect_entities(collection, child_node, category_name)
      end
    end
  end
end
