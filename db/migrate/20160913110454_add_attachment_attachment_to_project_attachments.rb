class AddAttachmentAttachmentToProjectAttachments < ActiveRecord::Migration[5.0]
  def change
    add_column :project_attachments, :attachment_file_name,    :string
    add_column :project_attachments, :attachment_content_type, :string
    add_column :project_attachments, :attachment_file_size,    :integer
    add_column :project_attachments, :attachment_updated_at,   :datetime
  end
end
