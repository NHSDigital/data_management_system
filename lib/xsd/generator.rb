# This module allows the construction of xsd components from individual classes
require 'builder'
module Xsd
  # methods for building xsd elements
  module Generator
    def build_element(schema_section, element_name, options = {})
      # adding block adds extra closing tag?
      return (schema_section.xs element_name, options) unless block_given?
      schema_section.xs element_name, options do
        yield schema_section
      end
    end

    # group should always really have something in it.
    def xsd_group(schema, name)
      return build_element(schema, :group, name: name) unless block_given?
      build_element(schema, :group, name: name) do
        yield schema
      end
    end

    def xsd_group_ref(schema, ref)
      build_element(schema, :group, ref: ref)
    end

    # sequence should always really have something in it.
    def xsd_sequence(schema)
      return build_element(schema, :sequence) unless block_given?
      build_element(schema, :sequence) do
        yield schema
      end
    end

    def xsd_restriction(schema, base)
      return (schema.xs :restriction, base: base) unless block_given?
      build_element(schema, :restriction, base: base) do
        yield schema
      end
    end

    def xsd_attribute(schema, options)
      build_element(schema, :attribute, options)
    end

    def xsd_simple_type(schema, name)
      return build_element(schema, :simpleType, name: name) unless block_given?
      build_element(schema, :simpleType, name: name) do
        yield schema
      end
    end

    def xsd_complex_type(schema, name)
      return (schema.xs :complexType, name: name) unless block_given?
      build_element(schema, :complexType, name: name) do
        yield schema
      end
    end

    def xsd_complex_type_tag(schema)
      build_element(schema, :complexType) do
        yield schema
      end
    end

    def xsd_complex_content(schema)
      build_element(schema, :complexContent) do
        yield schema
      end
    end

    def xsd_annotation(schema, annotation_text)
      schema.xs :annotation do |annotation|
        annotation.xs(:appinfo, annotation_text)
      end
    end

    def xsd_enumeration_value(schema, value)
      return (schema.xs :enumeration, value: value) unless block_given?
      schema.xs :enumeration, value: value do |_enumeration|
        yield schema
      end
    end

    def xsd_choice(schema_section, options = {})
      raise 'need options for a choice' unless block_given?
      schema_section.xs :choice, options do
        yield schema_section
      end
    end

    def xsd_include_schema(schema, value)
      schema.xs :include, schemaLocation: value
    end
  end
end
