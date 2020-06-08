class AddApprovalToProjects < ActiveRecord::Migration[5.0]
  def change
    add_column :projects, :details_approved, :boolean
    add_column :projects, :details_odr_approval_comments, :text
    add_column :projects, :members_approved, :boolean
    add_column :projects, :members_odr_approval_comments, :text
  end
end
