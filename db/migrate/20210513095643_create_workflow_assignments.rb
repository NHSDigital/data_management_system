class CreateWorkflowAssignments < ActiveRecord::Migration[6.0]
  def change
    create_table :workflow_assignments do |t|
      t.timestamps

      t.references :project_state,  null: false, index: true,  foreign_key: { to_table: :workflow_project_states }
      t.references :assigned_user,  null: false, index: true,  foreign_key: { to_table: :users }
      t.references :assigning_user, null: true,  index: false, foreign_key: { to_table: :users }
    end
  end
end
