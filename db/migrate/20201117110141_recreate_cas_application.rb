class RecreateCasApplication < ActiveRecord::Migration[6.0]
  def change
    drop_table :cas_applications

    create_table :cas_applications do |t|
      t.belongs_to :project
      t.string 'status'

      # 1. Requesterdetails
      t.string 'firstname'
      t.string 'surname'
      t.string 'jobtitle'
      t.string 'phe_email'
      t.string 'work_number'
      t.string 'organisation'
      t.string 'line_manager_name'
      t.string 'line_manager_email'
      t.string 'line_manager_number'
      t.string 'employee_type'
      t.date 'contract_startdate'
      t.date 'contract_enddate'

      # 2. Account details
      t.string 'username'
      t.text 'address'
      t.text 'n3_ip_address'

      # 3. Permissions
      t.text 'reason_justification'
      t.string 'access_level'
      t.string 'extra_datasets'
      t.string 'extra_datasets_rationale'

      # 4. Declaration
      t.string 'declaration'

      t.timestamps
    end
  end
end
