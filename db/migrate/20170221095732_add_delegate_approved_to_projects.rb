class AddDelegateApprovedToProjects < ActiveRecord::Migration[5.0]
  def change
    add_column :projects, :delegate_approved, :boolean
  end
end
