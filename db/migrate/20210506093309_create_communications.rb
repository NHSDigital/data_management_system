class CreateCommunications < ActiveRecord::Migration[6.0]
  def change
    create_table :communications do |t|
      t.timestamps

      t.references :project,      null: false, index: true, foreign_key: true
      t.bigint     :parent_id,    null: true,  index: true
      t.bigint     :sender_id,    null: false, index: true
      t.bigint     :recipient_id, null: false, index: true
      t.integer    :medium,       null: false, limit: 1
      t.datetime   :contacted_at, null: false
    end

    add_foreign_key :communications, :communications, column: :parent_id
    add_foreign_key :communications, :users, column: :sender_id
    add_foreign_key :communications, :users, column: :recipient_id
  end
end
