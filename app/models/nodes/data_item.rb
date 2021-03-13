module Nodes
  # Schema Data Items
  class DataItem < Node
    include Xsd::Generator
    include Nodes::DataItems::Validations

    belongs_to :node, class_name: 'Node', foreign_key: 'parent_id',
                      optional: true, inverse_of: :data_items
    belongs_to :entity, class_name: 'Nodes::Entity', foreign_key: 'parent_id',
                        optional: true, inverse_of: :data_items
    belongs_to :group, class_name: 'Nodes::Group', foreign_key: 'parent_id',
                       optional: true, inverse_of: :data_items
    belongs_to :choice, class_name: 'Nodes::Choice', foreign_key: 'parent_id',
                        optional: true, inverse_of: :data_items
    belongs_to :table, class_name: 'Nodes::Table', foreign_key: 'parent_id',
                       optional: true, inverse_of: :data_items
    belongs_to :data_item_group, class_name: 'Nodes::DataItemGroup', foreign_key: 'parent_id',
                                 optional: true, inverse_of: :data_items

    belongs_to :xml_type, optional: true
    belongs_to :data_dictionary_element, optional: true

    delegate :name, :link, :format_length, :national_codes,
             to: :data_dictionary_element, prefix: true, allow_nil: true

    def self.preload_strategy
      superclass.preload_strategy + [
        xml_type: { enumeration_values: :dataset_versions },
        data_dictionary_element: {
          xml_type: { enumeration_values: :dataset_versions }
        }
      ]
    end

    # If we have no data dictionary element yet, use direct association to xml_type
    def xmltype
      data_dictionary_element.present? ? data_dictionary_element.xml_type : xml_type
    end

    # TODO: search for data_item names that don't match the data dictionary name
    def xsd_element_name
      name.present? ? clean_name : data_dictionary_element.xsd_element_name
    end

    def clean_name
      word = name.gsub(/\(|\)|\&|\'/, '')
      word = word.gsub(/\+/, ' ')
      words = word.gsub(/\//, ' ').split
      words.map(&:downcase).map(&:camelize).join
    end

    def to_xsd(schema, category = nil)
      options = {
        name: xsd_element_name,
        minOccurs: min_occurs.to_s,
        maxOccurs: max_occurrences
      }
      options[:type] = item_type unless item_type.nil?

      build_element(schema, :element, options) do |element|
        build_element(element, :annotation) do |element_annotation|
          build_element(element_annotation, :appinfo, annotation.upcase)
        end
        attribute_reference(element) if use_attribute_reference?
      end
    end

    def item_type
      type = xmltype.name if xmltype.reference_xsd_type_directly?
      type = nil if use_attribute_reference?
      type
    rescue StandardError
      name
    end

    def attribute_reference(schema)
      xsd_complex_type_tag(schema) do |complex_type|
        xmltype.xml_attributes.each do |xml_attribute|
          xsd_attribute(complex_type, xml_attribute.attributes_for_xsd.merge(type: xmltype.name))
        end
      end
    end

    # If we want an attribute element or not
    # e.g
    # <BasisofDiagnosis code="1"/>
    # OR
    # <BasisofDiagnosis>1</BasisofDiagnosis>
    def use_attribute_reference?
      xmltype.xml_attributes.present?
    rescue StandardError
      raise name
    end

    def to_xml(xml, category = nil)
      return build_xml_with_attribute(xml) if xmltype.xml_attribute_for_value
      build_sample(xml)
    end

    def to_xml_choice(options)
      xml = options[:xml]
      return build_xml_with_attribute(xml) if xmltype.xml_attribute_for_value
      build_sample(xml)
    end

    # NHS Digital used attributes do store data
    # code      => lookups
    # extension => halfway house
    # value     => for nearly everything else
    def build_xml_with_attribute(xml)
      attrs =
        { xmltype.xml_attribute_for_value.name => xmltype.send(:sample_data, dataset_version) }
      xml.send(xsd_element_name, attrs)
    end

    def build_sample(xml)
      xml.send(xsd_element_name, xmltype.send(:sample_data, dataset_version))
    end

    def data_dictionary_element_name
      data_dictionary_element.try(:name)
    end

    def data_dictionary_element_name=(dde_name)
      return unless dde_name.present?
      self.data_dictionary_element = DataDictionaryElement.find_by(name: dde_name)
    end
  end
end
