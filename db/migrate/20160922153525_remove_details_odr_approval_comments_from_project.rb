class RemoveDetailsOdrApprovalCommentsFromProject < ActiveRecord::Migration[5.0]
  def change
    remove_column :projects, :details_odr_approval_comments, :text
    remove_column :projects, :members_odr_approval_comments, :text
  end
end
