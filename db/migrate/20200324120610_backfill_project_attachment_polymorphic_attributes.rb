class BackfillProjectAttachmentPolymorphicAttributes < ActiveRecord::Migration[6.0]
  def up
    ProjectAttachment.find_each do |attachment|
      attachment.update!(attachable_id: attachment.project_id, attachable_type: 'Project')
    end
  end

  def down
    ProjectAttachment.update_all(attachable_id: nil, attachable_type: nil)
  end
end
