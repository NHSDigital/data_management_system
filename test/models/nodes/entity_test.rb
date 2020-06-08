require 'test_helper'
module Nodes
  class EntityTest < ActiveSupport::TestCase
    test 'warn_against_no_child_nodes' do
      e = Entity.new(name: 'test', min_occurs: 0)
      e.valid?
      assert_equal 1, e.warnings.full_messages.length 
      assert_equal 'Node No Child nodes for Entity node', e.warnings.full_messages.first
    end
  end
end
