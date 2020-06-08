class CreateWorkflowCurrentProjectState < ActiveRecord::Migration[5.2]
  def up
    execute %{
      CREATE VIEW workflow_current_project_states AS
      SELECT t.id
      , t.project_id
      , p.state_id
      , p.user_id
      , p.created_at
      , p.updated_at
      FROM (
        SELECT project_id, MAX(id) AS id
        FROM workflow_project_states
        GROUP BY project_id
      ) t
      LEFT JOIN workflow_project_states p ON p.id = t.id;
    }
  end

  def down
    execute 'DROP VIEW workflow_current_project_states;'
  end
end
