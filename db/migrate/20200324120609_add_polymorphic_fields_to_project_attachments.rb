class AddPolymorphicFieldsToProjectAttachments < ActiveRecord::Migration[6.0]
  def change
    change_table :project_attachments do |t|
      t.references :attachable, polymorphic: true
    end

    ProjectAttachment.reset_column_information
  end
end
