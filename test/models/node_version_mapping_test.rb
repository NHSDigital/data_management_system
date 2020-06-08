require 'test_helper'
class NodeVersionMappingTest < ActiveSupport::TestCase
  test 'uniqueness' do
    dataset = Dataset.find_by(name: 'COSD')
    dv1 = dataset.dataset_versions.find_by(semver_version: '8.1')
    dv2 = dataset.dataset_versions.find_by(semver_version: '8.2')
    node1 = dv1.nodes.first.id
    node2 = dv2.nodes.first.id
    NodeVersionMapping.create!(node_id: node2, previous_node_id: node1)
    duplicate = NodeVersionMapping.new(node_id: node2, previous_node_id: node1)
    refute duplicate.valid?
    assert_includes duplicate.errors.details[:node_id], error: :taken, value: node2
  end

  test 'mapped nodes belong to same dataset' do
    dv1 = Dataset.find_by(name: 'COSD').dataset_versions.find_by(semver_version: '8.1')
    dv2 = Dataset.find_by(name: 'SACT').dataset_versions.find_by(semver_version: '2.0')
    node1 = dv1.nodes.first.id
    node2 = dv2.nodes.first.id
    mapped_node = NodeVersionMapping.new(node_id: node2, previous_node_id: node1)
    refute mapped_node.valid?
    error_msg = 'Nodes do not belong to same Dataset!'
    assert_includes mapped_node.errors.details[:dataset], error: error_msg
  end
end
