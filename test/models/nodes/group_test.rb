require 'test_helper'
module Nodes
  class GroupTest < ActiveSupport::TestCase
    test 'warn_against_no_child_nodes' do
      group_node = Nodes::Group.new(name: 'test')
      assert group_node.valid?
      refute group_node.safe?
      assert group_node.warnings.messages[:node].any? 'No Child nodes for Group node'
    end
  end
end
