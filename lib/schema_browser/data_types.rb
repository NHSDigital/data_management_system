module SchemaBrowser
  # Xml types page
  class DataTypes
    include Nodes::Utility
    include SchemaBrowser::Utility
    attr_accessor :zipfile, :html, :dataset, :version, :filename

    def initialize(zipfile, version, filename)
      @zipfile = zipfile
      @html = ''
      @depth = 0
      @index = true
      @version = version
      @dataset = version.dataset
      @filename = filename

      build
    end

    def build
      tag(:html) do
        head_common
        body_common do
          body_container_common do
            navbar
            data_types_content
          end
        end
      end
    end

    def data_types_content
      tag(:div, id: 'content', class: 'row') do
        tag(:div, class: 'span12') do
          tag(:h3) do
            content('Data Types')
          end
          data_types_table
        end
      end
    end

    def data_types_table
      version.send(:xml_types_for_version).each do |xmltype|
        tag(:table, class: 'table') do
          tag(:tr) do
            tag(:td) do
              tag(:a, name: xmltype.name)
              tag(:h4) do
                content(xmltype.name)
              end
              tag(:table, class: 'table-bordered') do
                xml_detail_head
                xml_detail_body(xmltype)
              end
            end
          end
        end
      end
    end

    def xml_detail_head
      tag(:thead) do
        tag(:th, width: '25%') do
          content('Attribute')
        end
        tag(:th, width: '75%') do
          content('Value')
        end
      end
    end

    IGNORED_XML_TYPE_FIELDS = %w[id created_at updated_at namespace_id annotation
                               xml_attribute_for_value_id].freeze

    def xml_detail_body(xmltype)
      tag(:tbody) do
        xml_key_detail(xmltype)
        attribute_for_value_detail(xmltype)
        enumeration_value_detail(xmltype)
      end
    end

    def xml_key_detail(xmltype)
      xml_keys = XmlType.attribute_names - IGNORED_XML_TYPE_FIELDS
      xml_keys.each do |xml_attr|
        next if xmltype.send(xml_attr).nil?

        tag(:tr) do
          tag(:td, style: 'width: 25%; text-align: left') do
            content(xml_attr.humanize)
          end
          tag(:td, style: 'width: 75%; text-align: left') do
            content(xmltype.send(xml_attr).to_s)
          end
        end
      end
    end

    def enumeration_value_detail(xmltype)
      return if xmltype.enumeration_values.blank?

      tag(:tr) do
        tag(:td, style: 'width: 25%; text-align: left') do
          content('Enumeration Values')
        end
        tag(:td, style: 'width: 75%; text-align: left') do
          xml_enumeration_value_table(xmltype)
        end
      end
    end

    def attribute_for_value_detail(xmltype)
      return if xmltype.xml_attribute_for_value.nil?

      tag(:tr) do
        tag(:td, style: 'width: 25%; text-align: left') do
          content('Attribute for value')
        end
        tag(:td, style: 'width: 25%; text-align: left') do
          attribute_for_value_table(xmltype)
        end
      end
    end

    def attribute_for_value_table(xmltype)
      tag(:table, class: 'table-striped table-sm') do
        attribute_for_value_table_head
        attribute_for_value_table_body(xmltype)
      end
    end

    def attribute_for_value_table_head
      tag(:thead) do
        tag(:th, width: '20%') do
          content('Name')
        end
        tag(:th, width: '80%') do
          content('Use')
        end
      end
    end

    def attribute_for_value_table_body(xmltype)
      tag(:tbody) do
        tag(:tr) do
          tag(:td) do
            content(xmltype.xml_attribute_for_value.name)
          end
          tag(:td) do
            content(xmltype.xml_attribute_for_value.use)
          end
        end
      end
    end

    def xml_enumeration_value_table(xmltype)
      tag(:table, class: 'table-striped table-sm') do
        xml_enumeration_value_table_head
        xml_enumeration_value_table_body(xmltype)
      end
    end

    def xml_enumeration_value_table_head
      tag(:thead) do
        tag(:th, width: '20%') do
          content('Enumeration Value')
        end
        tag(:th, width: '80%') do
          content('Annotation')
        end
      end
    end

    def xml_enumeration_value_table_body(xmltype)
      tag(:tbody) do
        xmltype.enumeration_values.for_version(version).sort_by(&:sort).each do |ev|
          tag(:tr) do
            tag(:td) do
              content(ev.enumeration_value)
            end
            tag(:td) do
              content(ev.annotation)
            end
          end
        end
      end
    end

    def save_file
      save_schema_pack_file(html, "schema_browser/#{filename}", zipfile)
    end
  end
end
