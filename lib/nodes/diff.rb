module Nodes
  # A lightweight class to wrap 1-2 Node instances, and compare the differences
  # between them.
  class Diff
    # Attributes that can change without being meaningful:
    IGNORED_FIELDS = %w[id name parent_id description dataset_version_id sort
                        created_at updated_at xml_type_id data_dictionary_element_id].freeze

    IGNORED_FIELDS_XMLTYPE = %w[namespace_id created_at updated_at].freeze

    class << self
      # Should the two given nodes be considered to represent the same node?
      def id_equal?(a, b, previous_version)
        id(a) == id(b) || mapped_to_each_other?(a, b, previous_version)
      end

      # Should return the "unique" identifier of the node, so far as is reasonable.
      def id(node)
        node.xsd_element_name
      end

      def mapped_to_each_other?(previous, current, previous_version)
        prev_node = current.previous_node_in(previous_version.semver_version)
        return false if prev_node.nil?

        prev_node.id == previous.id
      end

      # Have there been no changes at all between a and b?
      def unchanged?(a, b)
        changes(a, b).none?
      end

      # Returns a hash of meaningful attribute changes between a and b
      def changes(a, b)
        keys = Node.attribute_names - IGNORED_FIELDS
        keys += %w[parent_node_name xsd_element_name]
        diffs = keys.each_with_object({}) do |key, diff|
          old = a.send(key)
          new = b.send(key)
          diff[key] = [old, new] if old != new
        end
        diffs['xml_type'] = xml_diff(a, b) if a.data_item?
        diffs
      end

      def xml_diff(a, b)
        xml_attrs = XmlType.attribute_names - IGNORED_FIELDS_XMLTYPE
        xml_attrs.each_with_object({}) do |key, diff|
          old_attr = a.xmltype.send(key)
          new_attr = b.xmltype.send(key) unless b.entity? # special case for Address
          diff[key] = [old_attr, new_attr] if old_attr != new_attr
        end
      end
    end

    attr_accessor :old_node, :new_node, :child_nodes, :previous_version

    def initialize(old_node, new_node, previous_version = nil)
      raise 'need a node!' unless old_node || new_node

      @old_node = old_node
      @new_node = new_node
      @previous_version = previous_version
      @child_nodes = diff_children
    end

    def deletion?
      new_node.nil?
    end

    def addition?
      old_node.nil?
    end

    def not_relocated?
      return false if new_node.nil?

      children = new_node.child_nodes.each_with_object([]) do |node, c_nodes|
        c_nodes << node.previous_node_in(previous_version.semver_version)
      end
      children.compact.blank?
    end

    def changed?
      return false if deletion? || addition?

      changed_keys.any?
    end

    def changed_keys
      return [] if deletion? || addition?

      self.class.changes(old_node, new_node).keys
    end

    def changed_details
      return [] if deletion? || addition?

      self.class.changes(old_node, new_node)
    end

    def all_nodes
      child_nodes + child_nodes.flat_map(&:all_nodes)
    end

    def symbol
      return '-' if deletion?

      return '+' if addition?

      return '|' if changed?

      '='
    end

    private

    # Build up a collection of child elements, representing the diffs in child nodes:
    # when sorting by sort. nodes aren't treated as equal e.g Demographics
    # when sorted by xsd_element_name they are only equal if the alphabetical order is equal
    # e.g Demographics - PersonFamilyName doesn't work because it's knocked out of order
    # adding ability to diff nodes that are mapped to each between versions
    def diff_children
      # Diffing by xsd_element_name but print diff should use sort. see rake tasks.
      # Use NodeVersionMapping else default to sort by xsd_element_name
      new_children = new_node ? new_node.child_nodes : []
      # currently require every node to be mapped in a branch if using this to diff, otherwise
      # node is treated as new
      old_children = new_node ? mapped_nodes : []
      # binding.pry if new_node.name == 'LinkageDiagnosticDetails'
      # Default old nodes
      # If no mapped nodes for old children sort both new and old by Nodes::Diff.id and attempt diff
      if old_children.blank?
        old_children = old_node ? old_node.child_nodes.sort_by { |n| Nodes::Diff.id(n) } : []
        new_children = new_node ? new_node.child_nodes.sort_by { |n| Nodes::Diff.id(n) } : []
      end
      return old_children.map { |node| Nodes::Diff.new(node, nil, previous_version) } if deletion?
      return new_children.map { |node| Nodes::Diff.new(nil, node, previous_version) } if
        addition? && not_relocated?

      # for both lists, compute a Wagner-Fischer matrix, and then traverse to find
      # the minimum set of edits required to go from one to the other.
      wf = WagnerFischer.new(new_children, old_children) do |a, b|
        Nodes::Diff.id_equal?(a, b, previous_version)
      end
      map_to_diffs(wf.edit_sequence)
    end

    def mapped_nodes
      new_node.child_nodes.each_with_object([]) do |c_n, mapped|
        previous_node = c_n.previous_node_in(previous_version.semver_version)
        next if previous_node.nil?

        mapped << previous_node
      end
    end

    def map_to_diffs(edit_sequence)
      edit_sequence.flat_map do |e|
        case e.op
        when '+'
          Nodes::Diff.new(nil, e.b, previous_version)
        when '-'
          Nodes::Diff.new(e.a, nil, previous_version)
        when '|'
          # Represent a substitution (i.e. change of identifier) as
          # a removal and an addition rather than a "change":
          [Nodes::Diff.new(e.a, nil, previous_version), Nodes::Diff.new(nil, e.b, previous_version)]
        when '='
          # The is the same node, but the Nodes::Diff may decide
          # there have been changes to its properties:
          Nodes::Diff.new(e.a, e.b, previous_version)
        end
      end
    end
  end
end
