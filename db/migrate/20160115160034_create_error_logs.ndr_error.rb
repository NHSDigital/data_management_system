# This migration comes from ndr_error (originally 20150918162612)
# rubocop:disable all
# Adds partial ERROR_LOG table to schema (see README).
class CreateErrorLogs < ActiveRecord::Migration[5.0]
  def change
    create_table :error_logs, id: false do |t|
      t.string :error_logid, primary_key: true
      t.string :error_fingerprintid, index: true
      t.string :error_class
      t.text :description
      t.string :user_roles, length: 400
      t.text :lines
      t.text :parameters_yml
      t.string :url, length: 2000
      t.string :user_agent
      t.string :ip
      t.string :hostname
      t.string :database
      t.float :clock_drift
      t.string :svn_revision
      t.integer :port
      t.integer :process_id
      t.string :status

      t.timestamps
    end
  end
end
