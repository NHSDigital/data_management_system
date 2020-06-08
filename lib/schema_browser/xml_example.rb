module SchemaBrowser
  # Build xml examples of
  class XmlExample
    include SchemaBrowser::Utility
    include Nodes::Utility
    attr_accessor :zipfile, :xml, :node, :version, :filename

    def initialize(zipfile, parent_category_choice, node, filename, category_name = nil)
      @zipfile = zipfile
      @depth = 0
      @index = false
      @node = node
      @filename = filename
      @version = node.dataset_version

      parent_category_choice ? build_category_choice_children(category_name) : xml_node
    end

    def xml_node
      if node.entity? && node.categories.present?
        node.categories.sort_by(&:sort).pluck(:name).each do |category_name|
          build(category_name)
        end
      else
        build
      end
    end

    def build(category_name = nil)
      @xml = Nokogiri::XML::Builder.new do |xml|
        xml.send(version.header_one, 'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
                                     version.header_three => version.header_four) do
          # Temporarily set the namespace to nil so that child nodes do not use it
          parent_namespace = xml.parent.namespace
          xml.parent.namespace = nil
          node.to_xml(xml, category_name)
          # restore the parent namespace.
          xml.parent.namespace = parent_namespace
        end
      end
      @xml = @xml.to_xml
    end

    # to generate correct element tags for category_choice child_nodes
    def build_category_choice_children(category_name)
      @xml = Nokogiri::XML::Builder.new do |xml|
        xml.send(version.header_one, 'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
                                     version.header_three => version.header_four) do
          # Temporarily set the namespace to nil so that child nodes do not use it
          parent_namespace = xml.parent.namespace
          xml.parent.namespace = nil
          xml.send(category_name + node.name) do
            node.child_nodes.sort_by(&:sort).each do |child_node|
              child_node.to_xml(xml, category_name)
            end
          end
          # restore the parent namespace.
          xml.parent.namespace = parent_namespace
        end
      end
      @xml = @xml.to_xml
    end

    def save_file
      fname = "schema_browser/Examples/#{filename}.xml"
      save_schema_pack_file(@xml, fname, zipfile)
    end
  end
end
