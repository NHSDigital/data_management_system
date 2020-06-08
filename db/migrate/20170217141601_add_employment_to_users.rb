class AddEmploymentToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :employment, :string
    add_column :users, :contract_end_date, :date
    add_column :users, :directorate_id, :integer
    add_column :users, :division_id, :integer
    add_column :users, :delegate_user, :boolean
  end
end
