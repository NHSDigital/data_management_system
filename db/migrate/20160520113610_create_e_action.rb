# EAction migration
class CreateEAction < ActiveRecord::Migration[5.0]
  def rebuild
    drop
    change
  end

  def drop
    drop_table :e_action
  end

  def change
    create_table :e_action, id: false do |t|
      t.primary_key   :e_actionid, limit: 8
      t.integer   :e_batchid, limit: 8, index: true
      t.string    :e_actiontype, limit: 255
      t.datetime  :started
      t.string    :startedby, limit: 255
      t.datetime  :finished
      t.string    :comments, limit: 4000
      t.string    :status, limit: 255, index: true
      t.integer   :lock_version, limit: 8, default: 0, null: false
    end
  end
end
