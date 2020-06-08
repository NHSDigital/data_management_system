module SchemaBrowser
  # Auto Generate Dataset Schema Diagrams
  class Model
    include Nodes::Utility
    include SchemaBrowser::Utility
    attr_accessor :zipfile, :html, :node, :dataset, :version, :filename, :category_name

    def initialize(zipfile, node, filename, category_name = nil)
      @zipfile = zipfile
      @html = ''
      @depth = 0
      @index = false
      @node = node
      @version = node.dataset_version
      @dataset = version.dataset
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
            model
          end
        end
      end
    end

    def model
      tag(:div, class: 'model') do
        tag(:div, id: 'content', class: 'row') do
          tag(:div, class: 'span12') do
            tag(:body) do
              model_parent
              join_lines
              model_children
            end
          end
        end
      end
    end

    def model_parent
      tag(:svg, width: shape_width, height: shape_height) do
        tag(:a, href: "#{path}/Tabular/#{node.xsd_element_name}.html") do
          tag(:rect, options_shape)
          tag(:text, options_parent_text) do
            tag(:tspan, x: text_x, dy: 0) do
              content(node.xsd_element_name)
            end
            model_multiplicity
          end
        end
      end
    end

    def model_multiplicity
      return if node.group?

      tag(:tspan, x: text_x, dy: 15, 'font-weight' => 'normal') do
        content("[#{multiplicity(node)}]")
      end
    end

    def join_lines
      tag(:svg, width: label_width, height: shape_height) do
        child_nodes_for_category.sort_by(&:sort).each.with_index(1) do |child_node, i|
          # Min Occurrences
          tag(:text, options_min_occurrence_text(i)) do
            content(child_node.min_occurrences)
          end
          # Sort
          tag(:text, options_sequence_text(i)) do
            content("Sequence: #{i}")
          end
          # Max Occurrences
          tag(:text, options_max_occurrence_text(i)) do
            content(child_node.max_occurrences_star)
          end

          tag(:line, options_line(i))
        end
      end
    end

    def model_children
      return if child_nodes_for_category.empty?

      tag(:svg, width: child_shape_width, height: shape_height) do
        child_nodes_for_category.sort_by(&:sort).each.with_index(1) do |child_node, i|
          if child_node.data_item?
            child_data_item_shape(child_node, i)
          else
            tag(:a, href: "#{path}/Models/#{child_node.xsd_element_name}.html") do
              child_node_shape(child_node, i)
            end
          end
        end
      end
    end

    def child_data_item_shape(child_node, node_no)
      tag(:rect, options_child_shape(node_no, fill: 'lightgreen'))
      tag(:text, options_child_node_text(node_no)) do
        child_data_item_label(child_node)
      end
    end

    def child_data_item_label(child_node)
      tag(:tspan, x: child_text_x, dy: 0, 'font-weight' => 'bold') do
        content(child_node.xsd_element_name)
      end
      tag(:a, href: "#{path}/DataTypes.html##{child_node.xmltype.name}") do
        tag(:tspan, x: child_text_x, dy: 15) do
          content(child_node.xmltype.name)
        end
      end
    end

    def options_parent_text
      { x: text_x, y: text_y, 'text-anchor' => 'middle', 'alignment-baseline' => 'central',
        'font-weight' => 'bold' }
    end

    def options_min_occurrence_text(node_no)
      { fill: 'black', x: 0, y: child_text_y(node_no) + 15 }
    end

    def options_sequence_text(node_no)
      { fill: 'black', x: label_width / 2, y: child_text_y(node_no) - 10,
        'text-anchor' => 'middle' }
    end

    def options_max_occurrence_text(node_no)
      { fill: 'black', x: label_width - 10, y: child_text_y(node_no) + 15 }
    end

    def options_line(node_no)
      { x1: 0, y1: child_text_y(node_no), x2: label_width, y2: child_text_y(node_no),
        stroke: 'black', 'stroke-width' => 2 }
    end

    def child_node_shape(child_node, node_no, shape_options = {})
      tag(:rect, options_child_shape(node_no, shape_options))
      tag(:text, options_child_node_text(node_no)) do
        child_node_label(child_node)
      end
    end

    def options_child_node_text(node_no)
      { x: child_text_x, y: child_text_y(node_no),
        'text-anchor' => 'middle', 'alignment-baseline' => 'central' }
    end

    def child_node_label(child_node)
      label =
        child_node.choice? ? child_node.xsd_element_name + ' (Choice)' : child_node.xsd_element_name
      labels = [label]
      category_text = "(#{child_node.categories.pluck(:name).join(', ')})"
      labels << category_text if child_node.categories.present?
      labels.each_with_index do |lab, i|
        tag(:tspan, options_child_node_label_text(i, dy: 0)) do
          content(lab)
        end
      end
    end

    def options_child_node_label_text(text_line_no, options)
      child_node_label_text = { x: child_text_x }.merge(options)
      return child_node_label_text.merge('font-weight' => 'bold') if text_line_no.zero?

      child_node_label_text[:dy] += 15
      child_node_label_text
    end

    def label_width
      150
    end

    def options_shape
      {
        x: 0,
        y: 0,
        width: shape_width,
        height: shape_height,
        fill: 'cornsilk',
        stroke: 'black',
        'stroke-width' => 1,
        rx: 10
      }
    end

    def options_child_shape(child_node_no, options)
      {
        x: 0,
        y: child_y(child_node_no),
        width: child_shape_width,
        height: child_node_height,
        fill: 'powderblue',
        stroke: 'black',
        'stroke-width' => 1,
        rx: 10
      }.merge(options)
    end

    def child_y(node_no)
      return first_child_node_y if node_no.eql?(1)
      return last_child_node_y if node_no.eql?(child_nodes_for_category.length)

      first_child_node_y + (child_node_y_increment * (node_no - 1))
    end

    def child_text_x
      child_shape_width.to_i / 2
    end

    # maths for spacings
    def child_text_y(node_no)
      # first node
      return (first_child_node_y + (child_node_height / 2)) if node_no.eql?(1)
      # last node
      return (last_child_node_y + (child_node_height / 2)) if
        node_no.eql?(child_nodes_for_category.length)

      # nodes in the middle
      first_child_node_y + (child_node_y_increment * (node_no - 1)) + (child_node_height / 2)
    end

    # Also include xmltype name length if data item
    def child_shape_width
      child_node_name_lengths = child_nodes_for_category.map(&:xsd_element_name).map(&:length)
      return child_node_name_lengths.max * 10 unless
        child_nodes_for_category.any?(&:data_item?)

      # add xmltype names
      child_nodes_for_category.map do |c_n|
        next unless c_n.data_item?

        child_node_name_lengths << c_n.xmltype.name.length
      end

      child_node_name_lengths.max * 10
    end

    def shape_width
      @shape_width ||= node.xsd_element_name.length * 10
    end

    def shape_height
      @shape_height ||= child_nodes_for_category.length * 100
    end

    def text_x
      shape_width / 2
    end

    def text_y
      shape_height / 2
    end

    def child_node_height
      @child_node_height ||= ((shape_height / 2) / child_nodes_for_category.length)
    end

    def child_nodes_for_category
      @child_nodes_for_category ||=
        if category_name.nil?
          node.child_nodes.sort_by(&:sort)
        else
          node.child_nodes.sort_by(&:sort).each_with_object([]) do |c_n, for_category|
            for_category << c_n if c_n.node_for_category?(category_name)
          end
        end
    end

    # start with a gap
    def first_child_node_y
      child_node_height / 2
    end

    # position of bottom child
    def last_child_node_y
      shape_height - (child_node_height * 1.5)
    end

    def child_node_y_increment
      (last_child_node_y - first_child_node_y) / (child_nodes_for_category.length - 1)
    end

    def save_file
      fname = "schema_browser/Models/#{filename}.html"
      save_schema_pack_file(html, fname, zipfile)
    end
  end
end
