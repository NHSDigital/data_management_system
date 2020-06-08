# ZEType
class CreateZEType < ActiveRecord::Migration[5.0]
  def rebuild
    drop
    change
  end

  def drop
    drop_table :ze_type
  end

  def change
    create_table :ze_type, id: false do |t|
      t.string    :ze_typeid, limit: 255, primary_key: true, null: false
      t.string    :shortdesc, limit: 64
      t.string    :description, limit: 255
      t.datetime  :startdate
      t.datetime  :enddate
      t.integer   :sort, limit: 8 # bigint
      t.string    :comments, limit: 255
    end
  end
end
