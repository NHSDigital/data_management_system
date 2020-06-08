module SchemaBrowser
  # Gemerate the core 'Other' page
  class Other
    include Nodes::Utility
    include SchemaBrowser::Utility
    include SchemaBrowser::UtilityCategory
    attr_accessor :zipfile, :html, :dataset, :version

    def initialize(zipfile, version)
      @zipfile = zipfile
      @html = ''
      @depth = 0
      @index = false
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
            core_content
          end
        end
      end
    end

    def core_content
      tag(:div, id: 'content', class: 'row') do
        tag(:div, class: 'span12') do
          category_table do
            common_entities.each do |cat_entity|
              table_row_category(cat_entity.xsd_element_name)
            end
          end
        end
      end
      tag(:div, id: 'push')
    end

    def common_entities
      collect_core_entities(for_cat = [], version.version_entity)
      for_cat
    end

    def collect_core_entities(collection, node)
      node.child_nodes.sort_by(&:sort).each do |child_node|
        collection << child_node if
          child_node.entity? && core_entity?(child_node) &&
          !child_node.parent_node&.category_choice? # we'll deal with CategoryChoice elements later
        collect_core_entities(collection, child_node)
      end
    end

    # TODO: should probably be a method in node.rb to handle this scenario
    # e.g TreatmentUrological has a category but it's sub entity TreatmentBladder does not it
    # I think because this broke schema generation
    def core_entity?(node)
      node.belongs_to_all_categories? && traverse_to_parent_entity(node).belongs_to_all_categories?
    end

    def traverse_to_parent_entity(node)
      return node.parent_node if node.parent_node.entity?

      traverse_to_parent_entity(node.parent_node)
    end

    def save_file
      save_schema_pack_file(html, 'schema_browser/Categories/Other.html', zipfile)
    end
  end
end
