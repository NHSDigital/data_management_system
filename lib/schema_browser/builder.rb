module SchemaBrowser
  # Build the schema browser
  class Builder
    attr_accessor :zipfile, :dataset, :version, :version_previous, :components

    def initialize(dataset, version, version_previous, zipfile = nil)
      @zipfile = zipfile
      @dataset = dataset
      @version = version
      @version_previous = version_previous
      @components = []

      build
    end

    def build
      index
      change_log
      data_types
      categories
      category_choices
      other
      models
      tabular
      schema_examples
      xml_examples
      add_browser_templates
    end

    def index
      add_to_build(SchemaBrowser::Index.new(zipfile, version))
    end

    # Generate the Change log and associated html page
    def change_log
      add_to_build(SchemaBrowser::ChangeLog.new(zipfile, version, version_previous, 'ChangeLog'))
    end

    def data_types
      add_to_build(SchemaBrowser::DataTypes.new(zipfile, version, 'DataTypes.html'))
    end

    def categories
      cats = version_categories.pluck(:name)
      cats.each do |category_name|
        add_to_build(SchemaBrowser::Category.new(zipfile, version, category_name))
      end
    end

    def category_choices
      version.category_choices.each do |category_choice|
        add_to_build(SchemaBrowser::CategoryChoice.new(zipfile, category_choice))
      end
    end

    def other
      add_to_build(SchemaBrowser::Other.new(zipfile, version))
    end

    # # for an entity, show it's data_items (and child entities if applicable)
    def tabular
      tabular_nodes = %i[entities groups choices]
      tabular_nodes.each do |node_type|
        version.send(node_type).each do |node|
          if node.parent_node&.category_choice? # i.e record
            version.categories.sort_by(&:sort).pluck(:name).each do |category_name|
              filename = "#{category_name}#{node.xsd_element_name}"
              add_to_build(SchemaBrowser::Tabular.new(zipfile, node, filename, category_name))
            end
          else
            add_to_build(SchemaBrowser::Tabular.new(zipfile, node, node.xsd_element_name))
          end
        end
      end
    end

    def schema_examples
      tabular_nodes = %i[entities groups]
      tabular_nodes.each do |node_type|
        version.send(node_type).each do |node|
          if node.parent_node&.category_choice? # i.e record
            version.categories.sort_by(&:sort).pluck(:name).each do |category_name|
              filename = "#{category_name}#{node.xsd_element_name}"
              add_to_build(SchemaBrowser::SchemaExample.new(zipfile, true, node,
                                                            filename, category_name))
            end
          else
            add_to_build(SchemaBrowser::SchemaExample.new(zipfile, false, node,
                                                          node.xsd_element_name))
          end
        end
      end
    end

    def xml_examples
      tabular_nodes = %i[entities groups]
      tabular_nodes.each do |node_type|
        version.send(node_type).each do |node|
          if node.parent_node&.category_choice? # i.e record
            version.categories.sort_by(&:sort).pluck(:name).each do |category_name|
              filename = "#{category_name}#{node.xsd_element_name}"
              add_to_build(SchemaBrowser::XmlExample.new(zipfile, true, node,
                                                         filename, category_name))
            end
          else
            add_to_build(SchemaBrowser::XmlExample.new(zipfile, false, node, node.xsd_element_name))
          end
        end
      end
    end

    def models
      tabular_nodes = %i[entities groups choices]
      tabular_nodes.each do |node_type|
        version.send(node_type).each do |node|
          if node.parent_node&.category_choice? # i.e record
            version.categories.sort_by(&:sort).pluck(:name).each do |category_name|
              filename = "#{category_name}#{node.xsd_element_name}"
              add_to_build(SchemaBrowser::Model.new(zipfile, node, filename, category_name))
            end
          elsif node.entity? && node.categories.present?
            node.categories.sort_by(&:sort).pluck(:name).each do |category_name|
              add_to_build(SchemaBrowser::Model.new(zipfile, node,
                                                    node.xsd_element_name, category_name))
            end
          else
            add_to_build(SchemaBrowser::Model.new(zipfile, node, node.xsd_element_name))
          end
        end
      end
    end

    # TODO: duplicated in utility
    def version_categories
      (version.categories - [version.core_category]).sort_by(&:sort)
    end

    def add_to_build(klass)
      components << klass
    end
    
    def add_browser_templates
      zip_file_path = 'schema_browser/Template/'
      folder_to_copy = Rails.root.join('lib', 'schema_browser', 'Template')
      z = ZipFolderCopy.new(folder_to_copy, zipfile, zip_file_path)
      z.write
    end 
  end
end
