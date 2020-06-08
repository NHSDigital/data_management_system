class AddDigestToProjectAttachments < ActiveRecord::Migration[5.2]
  def change
    add_column :project_attachments, :digest, :string
  end
end
