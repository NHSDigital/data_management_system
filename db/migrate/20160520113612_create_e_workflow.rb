# EWorflow
class CreateEWorkflow < ActiveRecord::Migration[5.0]
  def rebuild
    drop
    change
  end

  def drop
    drop_table :e_workflow
  end

  def change
    create_table :e_workflow, id: false do |t|
      t.primary_key   :e_workflowid, limit: 8
      t.string    :e_type, limit: 255
      t.string    :provider, limit: 255
      t.string    :last_e_actiontype, limit: 255
      t.string    :next_e_actiontype, limit: 255
      t.string    :comments, limit: 255
      t.integer   :sort, limit: 2   # smallint
    end

    add_index :e_workflow, [:e_type, :last_e_actiontype, :next_e_actiontype],
                :name => 'e_workflow_etype_leat_neat_ix'
  end
end
