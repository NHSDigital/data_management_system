class CreateWorkflowState < ActiveRecord::Migration[5.2]
  def change
    create_table :workflow_states, id: false do |t|
      t.string :id, primary_key: true
      t.string :description
      t.timestamps
    end
  end
end
