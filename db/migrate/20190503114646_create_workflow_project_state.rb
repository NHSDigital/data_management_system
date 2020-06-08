class CreateWorkflowProjectState < ActiveRecord::Migration[5.2]
  def change
    create_table :workflow_project_states do |t|
      t.string  :state_id,   null: false, index: true
      t.integer :project_id, null: false, index: true
      t.integer :user_id, index: true
      t.timestamps

      t.foreign_key :workflow_states, column: :state_id
      t.foreign_key :projects
      t.foreign_key :users
    end
  end
end
