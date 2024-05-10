require 'rainbow'

module Nodes
  # build a change log to txt file
  class ChangeLog
    include Nodes::Utility
    include Nodes::XmlTypeDiff
    include SchemaBrowser::Utility
    attr_accessor :zipfile, :filename, :txt, :dataset, :dv1, :dv2

    PRINT_XML_FIELDS = %w[xml_type].freeze

    XML_TYPE_IGNORED_FIELDS = %w[id created_at updated_at namespace_id annotation
                                 xml_attribute_for_value_id].freeze

    REFER_TO_NEW_TYPE = " Refer to new TYPE changes)\n".freeze

    ELEMENT_FIELDS = %w[min_occurs max_occurs].freeze

    COSMETIC_ELEMENT_FIELDS = %w[reference annotation description].freeze

    XML_TYPE_FIELDS = %w[min_length max_length restriction fractiondigits
                         totaldigits xml_attribute_for_value].freeze

    COSMETIC_XML_TYPE_FIELDS = %w[annotation].freeze

    def initialize(dataset, dv1, dv2, output, zipfile = nil)
      @zipfile = zipfile
      @filename = "#{dataset.name}_v#{dv2.semver_version}_change_log.txt"
      @txt = ''
      @depth = 0
      @dataset = dataset
      @dv1 = dv1
      @dv2 = dv2
      @output = output

      nd = Nodes::Diff.new(dv1.version_entity, dv2.version_entity, dv1)
      # TODO: minInclusive
      header
      xml_type_changes(dv2, dv1)
      schema_details_header
      schema_diff = print_node_diffs([nd])
      puts schema_diff if output
    end

    def print_node_diffs(diffs, category = nil, buffer = [])
      diffs.each do |diff|
        # colour = { '+' => 'green', '-' => 'red', '=' => 'white', '|' => 'yellow' }[diff.symbol]

        case diff.symbol
        when '+'
          element_additions(diff, category)
          buffer << Rainbow("+#{' ' * (@depth * 2)}#{node_name(diff.new_node)}").green
        when '-'
          buffer << Rainbow("-#{' ' * (@depth * 2)}#{diff.old_node.xsd_element_name}").red
        when '|'
          # Currently the old and new names are always the same, because that's
          # the key used to define identity. However, this could change.
          element_changes(diff, category)
          buffer << Rainbow("±#{' ' * (@depth * 2)}#{diff.old_node.xsd_element_name} -> " \
                            "#{node_name(diff.new_node)} #{diff.changed_details}").yellow
        when '='
          element_no_changes(diff)
          buffer << Rainbow(" #{' ' * (@depth * 2)}#{diff.old_node.xsd_element_name}")
        end
        @depth += 1
        print_node_diffs(diff.child_nodes.sort_by { |cn| cn.new_node&.sort || cn.old_node&.sort },
                         category, buffer)
        @depth -= 1
      end

      buffer if @output
    end

    def header
      change_log_text("#{dataset.name} v#{dv2.semver_version} Schema Change Log\n")
      change_log_text("#{Date.current.strftime('%Y/%m/%d')}\n")
      change_log_text("Version #{dv1.semver_version} to #{dv2.semver_version}\n\n")
    end

    def schema_details_header
      change_log_text("SCHEMA DETAILS\n\n")
    end

    def print_for_category?(diff, category)
      return unless diff.new_node
      return true if core_node(diff.new_node) &&
                     category.name == category.dataset_version.core_category.name
      return true if core_node(diff.new_node) || diff.new_node.belongs_to_category?(category.name)
    end

    def core_node(node)
      return if node.categories.present?

      node.belongs_to_all_categories? || node.parent_node.belongs_to_all_categories?
    end

    def element_additions(diff, category = nil)
      return category_choice_comment(diff, category) if
        diff.new_node.parent_node.category_choice?

      divider if diff.new_node.entity?
      category_comment(diff) if category.nil?
      send("#{diff.new_node.type.split('::').last.underscore}_addition", diff)
    end

    def category_choice_addition(diff)
      change_log_text("*** #{node_name(diff.new_node)} ***\n")
      change_log_text("  - Create Choice\n")
    end

    def data_item_addition(diff)
      change_log_text("*** #{node_name(diff.new_node)} ***\n")
      change_log_text("  - Create attribute: '#{node_name(diff.new_node)}'\n")
      change_log_text("  - Create as Type: '#{diff.new_node.xmltype.name}'\n")
      change_log_text("  - Create multiplicity as: #{multiplicity(diff.new_node)}\n\n")
    end

    def entity_addition(diff)
      change_log_text("*** Section Name: #{node_name(diff.new_node)} ***\n")
      change_log_text("  - Nested class in: '#{diff.new_node.parent_node&.name}'\n")
      change_log_text("  - Create element: '#{node_name(diff.new_node)}'\n")
      change_log_text("  - Create multiplicity as: #{multiplicity(diff.new_node)}\n\n")
    end

    def group_addition(diff)
      change_log_text("*** #{node_name(diff.new_node)} ***\n")
      change_log_text("  - Nested class in: #{diff.new_node.parent_node&.name}\n")
      change_log_text("  - Create: #{node_name(diff.new_node)} group\n\n")
    end

    # TODO: this is not part of XML. change instructions
    def choice_addition(diff)
      change_log_text("*** Group Name: Choice (#{node_name(diff.new_node)}) ***\n")
      change_log_text("  - Nested class in: '#{diff.new_node.parent_node&.name}'\n")
      choice_addition_comments(diff.new_node)
    end

    def choice_addition_comments(choice)
      if choice.min_occurs.positive? && choice.min_occurs != choice.max_occurrences
        text = "  - At least #{choice.min_occurs} of the following MUST be present " \
               "#{choice.max_occurrences} allowed\n"
        change_log_text(text)
      elsif choice.min_occurs.positive?
        change_log_text("  - Only #{choice.min_occurs} of the following must be present\n")
      elsif choice.min_occurs.zero? && choice.max_occurs.present?
        text = "  - #{choice.max_occurs} occurrences of each the following can be present\n"
        change_log_text(text)
      end
      choice.child_nodes.map(&:xsd_element_name).each do |n|
        change_log_text("  -- #{n}\n")
      end

      new_line
    end

    def relocation_comment(diff)
      return if diff.new_node.parent_node_name == diff.old_node.parent_node_name

      text = "- PARENT CLASS: '#{diff.new_node.parent_node_name}' " \
             "previously: #{diff.old_node.parent_node_name}\n"
      change_log_text(text)
    end

    def element_changes(diff, category)
      divider if diff.new_node.entity?
      category_comment(diff) if category.nil?
      change_log_text("*** #{diff.old_node.xsd_element_name} ***\n")

      change_log_text("Changes: \n")

      relocation_comment(diff)

      unless element_names_equal?(diff)
        text = "- ELEMENT NAME: '#{node_name(diff.new_node)}' previously: " \
               "'#{diff.old_node.xsd_element_name}'\n"
        change_log_text(text)
      end
      if diff.changed_details.keys.include? 'xml_type'
        change_log_text("- ELEMENT TYPE: '#{diff.changed_details['xml_type']['name'].last}'\n") if
          diff.changed_details['xml_type'].present?
      end

      ELEMENT_FIELDS.each do |f|
        val_diffs = diff.changed_details[f]
        next if val_diffs.blank?

        text = "- #{f.upcase}: Change from " \
               "#{val_diffs.first || 'Null'} to #{val_diffs.last || 'Unbounded'}\n"
        change_log_text(text)
      end

      new_line
    end

    def element_no_changes(diff)
      return if diff.new_node.group?

      if diff.new_node.entity? || diff.new_node.choice?
        divider
        change_log_text("*** Section Name: #{node_name(diff.new_node)} ***\n")
      else
        change_log_text("*** #{node_name(diff.new_node)} ***\n")
      end
      change_log_text("Changes:\n")
      change_log_text("- Null\n\n")
    end

    def category_comment(diff)
      return if diff.new_node.categories.blank?

      text = "*** Applicable categories: #{diff.new_node.categories.map(&:name).join(' ')} ***\n"
      change_log_text(text)
    end

    CAT_CHOICE_COMMENT = '   Choosing one of the following determines what elements can ' \
                         "be included in the choice\n".freeze

    CAT_NODE_CHOICES_COMMENT = "   xsd_element_name choices:\n".freeze

    def category_choice_comment(diff, category)
      if category.nil?
        change_log_text(CAT_CHOICE_COMMENT)
        change_log_text(CAT_NODE_CHOICES_COMMENT)
        diff.new_node.dataset_version.categories.sort_by(&:sort).pluck(:name).each do |name|
          change_log_text("    - #{name + diff.new_node.name}\n")
        end
      else
        change_log_text("*** Section Name: #{node_name(diff.new_node)} ***\n")
        change_log_text("  - Choose element: #{category.name + node_name(diff.new_node)}\n")
        change_log_text("  - Nested class in: '#{diff.new_node.parent_node&.name}'\n")
        change_log_text("  - Create element: '#{node_name(diff.new_node)}'\n")
        change_log_text("  - Create multiplicity as: #{multiplicity(diff.new_node)}\n\n")
      end
    end

    def node_name(node)
      node.xsd_element_name
    end

    def change_log_text(text)
      @txt << indent + text
    end

    def element_names_equal?(diff)
      diff.old_node.xsd_element_name == diff.new_node.xsd_element_name
    end

    def divider
      @txt << "#{'-' * 100}\n"
    end

    def new_line
      @txt << "\n"
    end

    def save_file
      if zipfile.nil?
        File.open(Rails.root.join('tmp', 'change_logs', filename), 'w') do |f|
          f.write txt
        end
      else
        zipfile.get_output_stream("change_log/#{filename}") { |f| f.write txt }
      end
    end
  end
end
