class CreateWorkflowTransition < ActiveRecord::Migration[5.2]
  def change
    create_table :workflow_transitions do |t|
      t.integer :project_type_id, index: true
      t.string  :from_state_id,   null: false, index: true
      t.string  :next_state_id,   null: false, index: true
      t.timestamps

      t.foreign_key :project_types
      t.foreign_key :workflow_states, column: :from_state_id
      t.foreign_key :workflow_states, column: :next_state_id
    end
  end
end
