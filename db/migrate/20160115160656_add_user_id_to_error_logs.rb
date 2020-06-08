class AddUserIdToErrorLogs < ActiveRecord::Migration[5.0]
  def change
    add_column :error_logs, :user_id, :integer
  end
end
