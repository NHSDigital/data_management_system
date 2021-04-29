# plan.io 23845 - Add amendment_approved_date to project_amendments
class AddAmendmentApprovedDateToAmendments < ActiveRecord::Migration[6.0]
  def change
    add_column :project_amendments, :amendment_approved_date, :date
  end
end
