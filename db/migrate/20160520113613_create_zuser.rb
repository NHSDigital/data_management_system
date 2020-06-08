# ZUser
class CreateZuser < ActiveRecord::Migration[5.0]
  def rebuild
    drop
    change
  end

  def drop
    drop_table :zuser
  end

  def change
    create_table :zuser, id: false do |t|
      t.string    :zuserid, limit: 255, primary_key: true, default: 1, null: false
      t.string    :shortdesc, limit: 64
      t.string    :description, limit: 2000
      t.string    :exportid, limit: 64
      t.datetime  :startdate
      t.datetime  :enddate
      t.integer   :sort, limit: 8 # bigint
      t.string    :registryid, limit: 5
      t.string    :qa_supervisorid, limit: 255
    end
  end
end
