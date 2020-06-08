class CreateProjectAmendments < ActiveRecord::Migration[6.0]
  def change
    create_table :project_amendments do |t|
      t.references :project,      foreign_key: true
      t.datetime   :requested_at, null: false
      t.string     :labels,       array: true, default: []

      t.timestamps
    end
  end
end
