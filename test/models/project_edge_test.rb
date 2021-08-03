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

  test 'transitive_closure_for scope' do
    project                    = projects(:dummy_project)
    directly_related_project   = projects(:test_application)
    indirectly_related_project = projects(:one)

    scope = ProjectEdge.transitive_closure_for(project)

    assert_equal 2, scope.count
    assert_equal 1, scope.where(related_project: directly_related_project).count
    assert_equal 1, scope.where(related_project: indirectly_related_project).count

    edge = scope.find_by(related_project: directly_related_project)
    path = [project.id, directly_related_project.id]
    assert_equal 1, edge.distance
    assert_equal path, edge.path

    edge = scope.find_by(related_project: indirectly_related_project)
    path = [project.id, directly_related_project.id, indirectly_related_project.id]
    assert_equal 2, edge.distance
    assert_equal path, edge.path
  end

  test 'transitive_closure_for scope with distinct modifier' do
    project                    = projects(:dummy_project)    # A
    directly_related_project   = projects(:test_application) # B
    indirectly_related_project = projects(:one)              # C
    multiple_path_project      = projects(:two)              # D

    directly_related_project.left_relationships.create!(right_project: multiple_path_project)
    indirectly_related_project.left_relationships.create!(right_project: multiple_path_project)

    scope = ProjectEdge.transitive_closure_for(project)

    # Sanity check...
    # A -> B
    # A -> B -> C
    # A -> B -> D
    # A -> B -> C -> D
    # A -> B -> D -> C
    assert_equal 5, scope.count
    assert_equal 2, scope.where(related_project: multiple_path_project).count

    scope = ProjectEdge.transitive_closure_for(project, distinct: true)

    assert_equal 3, scope.count
    assert_equal 1, scope.where(related_project: multiple_path_project).count

    edge = scope.find_by(related_project: multiple_path_project)
    path = [project.id, directly_related_project.id, multiple_path_project.id]
    assert_equal 2, edge.distance
    assert_equal path, edge.path
  end
end
