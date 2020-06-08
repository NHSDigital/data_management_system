# EBatch
class CreateEBatch < ActiveRecord::Migration[5.0]
  def rebuild
    drop
    change
  end

  def drop
    drop_table :e_batch
  end

  def change
    create_table :e_batch, id: false do |t|
      t.primary_key   :e_batchid, limit: 8
      t.string    :e_type, limit: 255
      t.string    :provider, limit: 255
      t.string    :media, limit: 255
      t.string    :original_filename, limit: 255
      t.string    :cleaned_filename, limit: 255
      t.integer   :numberofrecords, limit: 8    # bigint
      t.datetime  :date_reference1
      t.datetime  :date_reference2
      t.integer   :e_batchid_traced, limit: 8
      t.string    :comments, limit: 255
      t.string    :digest, limit: 40
      t.integer   :lock_version, limit: 8, default: 0, null: false
      t.string    :inprogress, limit: 50
      t.string    :registryid, limit: 255
      t.integer   :on_hold, limit: 2    # smallint
    end

    add_index :e_batch, [:registryid, :e_type, :provider]
  end
end
