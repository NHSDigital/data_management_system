class AddAssignedUserToWorkflowCurrentState < ActiveRecord::Migration[6.0]
  def up
    execute %{
      DROP VIEW workflow_current_project_states;
      CREATE VIEW workflow_current_project_states AS
      SELECT t.id
      , t.project_id
      , p.state_id
      , p.user_id
      , u.assigned_user_id
      , u.assigning_user_id
      , p.created_at
      , p.updated_at
      FROM (
        SELECT project_id, MAX(id) AS id
        FROM workflow_project_states
        GROUP BY project_id
      ) t
      LEFT JOIN workflow_project_states p ON p.id = t.id
      LEFT JOIN LATERAL (
        SELECT assigned_user_id
        , assigning_user_id
        FROM workflow_assignments
        WHERE project_state_id = t.id
        ORDER BY id DESC
        LIMIT 1
      ) u ON true;
    }
  end

  def down
    execute %{
      DROP VIEW workflow_current_project_states;
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
end
