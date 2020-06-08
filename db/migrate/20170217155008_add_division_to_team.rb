class AddDivisionToTeam < ActiveRecord::Migration[5.0]
  def change
    add_column :teams, :division_id, :integer
    add_column :teams, :directorate_id, :integer
    add_column :teams, :delegate_approver, :integer
  end
end
