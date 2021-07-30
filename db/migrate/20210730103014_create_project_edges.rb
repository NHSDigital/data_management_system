class CreateProjectEdges < ActiveRecord::Migration[6.0]
  def up
    execute <<~SQL.squish
      CREATE VIEW project_edges AS
      SELECT id AS project_relationship_id
      , left_project_id AS project_id
      , right_project_id AS related_project_id
      , created_at
      , updated_at
      FROM project_relationships
      UNION
      SELECT id AS project_relationship_id
      , right_project_id AS project_id
      , left_project_id AS related_project_id
      , created_at
      , updated_at
      FROM project_relationships;
    SQL
  end

  def down
    execute <<~SQL.squish
      DROP VIEW IF EXISTS project_edges;
    SQL
  end
end
