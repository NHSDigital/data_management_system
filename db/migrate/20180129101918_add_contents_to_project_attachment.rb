class AddContentsToProjectAttachment < ActiveRecord::Migration[5.0]
  def change
    add_column :project_attachments, :attachment_contents, :binary  
  end
end
