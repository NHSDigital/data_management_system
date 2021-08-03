# Helper class built upon a view over the `project_relationships` table, which pivots those records
# into something a little easier to query because:
# - managing a join model is easy.
# - querying both sides of a join table because a resource may exist on either FK is hard.
# - querying an adjaceny list is easy.
# - managing adjaceny lists for inverse pairs of records via ActiveRecord callbacks is like
#   sticking your head inside an aligator's mouth; it's all good until it inevitably bites.
class ProjectEdge < ApplicationRecord
  belongs_to :project_relationship
  belongs_to :project
  belongs_to :related_project, class_name: 'Project'

  class << self
    # Returns an expanded set of `ProjectEdge`s for `project`, containing edges for both directly
    # related projects and those that are indirectly related through one or more intermediates.
    # Related projects may be returned multiple times if it can be reached via many different
    # paths. Passing the `distinct` option with a truthy value will limit the returned set to only
    # include unique related projects (selected by the shortest path).
    #
    # NOTE: This can be a costly query and as such may be a performance problem area. Will probably
    #       want to see/capture some stats from usage in the wild...
    def transitive_closure_for(project, **options)
      from(<<~SQL.squish)
        (
          #{transitive_closure_cte(project)}
          #{transitive_closure_query(distinct: options[:distinct])}
        ) #{quoted_table_name}
      SQL
    end

    private

    def transitive_closure_cte(project)
      sanitize_sql([<<~SQL.squish, project.id])
        WITH RECURSIVE transitive_closure(project_id, related_project_id, distance, path) AS (
          SELECT project_id
          , related_project_id
          , 1 AS distance
          , ARRAY[project_id, related_project_id] AS path
          FROM project_edges
          WHERE project_id = ?

          UNION ALL

          SELECT t.project_id
          , e.related_project_id
          , t.distance + 1
          , t.path || e.related_project_id AS path
          FROM project_edges e
          JOIN transitive_closure t on e.project_id = t.related_project_id
          WHERE NOT t.path && ARRAY[e.related_project_id]
        )
      SQL
    end

    def transitive_closure_query(distinct: false)
      if distinct
        <<~SQL.squish
          SELECT DISTINCT ON (related_project_id) *
          FROM transitive_closure
          ORDER BY related_project_id, distance
        SQL
      else
        <<~SQL.squish
          SELECT *
          FROM transitive_closure
        SQL
      end
    end
  end

  # This model is backed by a database view.
  def readonly?
    true
  end
end
