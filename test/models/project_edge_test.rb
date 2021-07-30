require 'test_helper'

# Tests the behaviour of the ProjectEdge class.
class ProjectEdgeTest < ActiveSupport::TestCase
  test 'pivots the project_edges table' do
    relationship  = project_relationships(:dummy_project_test_application)
    project       = relationship.left_project
    related       = relationship.right_project

    scope = ProjectEdge.where(project_relationship: relationship)

    assert_equal 2, scope.count
    assert_equal 1, scope.where(project: project, related_project: related).count
    assert_equal 1, scope.where(project: related, related_project: project).count
  end

  test 'is read only' do
    relationship = project_relationships(:dummy_project_test_application)

    edge = ProjectEdge.new(
      project_relationship: relationship,
      project:              relationship.left_project,
      related_project:      relationship.right_project
    )

    assert edge.readonly?

    assert_raises ActiveRecord::ReadOnlyRecord do
      edge.save(validate: false)
    end
  end
end
