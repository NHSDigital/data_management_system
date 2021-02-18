# plan.io 25793
# Add cas form user details columns to users table
class AddCasFormUserDetailsColumnsToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :line_manager_name, :string
    add_column :users, :line_manager_email, :string
    add_column :users, :line_manager_telephone, :string
    add_column :users, :contract_start_date, :date
  end
end
