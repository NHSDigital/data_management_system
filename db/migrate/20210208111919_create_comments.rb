class CreateComments < ActiveRecord::Migration[6.0]
  def change
    create_table :comments do |t|
      t.timestamps
      t.references :user,        null: false, foreign_key: true
      t.references :commentable, null: false, polymorphic: true
      t.string     :body,        null: false
      t.jsonb      :metadata,    null: false, default: {}
    end
  end
end
