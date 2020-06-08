class AddProjectStateIdToProjectAmendments < ActiveRecord::Migration[6.0]
  def change
    add_reference :project_amendments, :project_state, foreign_key: { to_table: :workflow_project_states }
  end
end
