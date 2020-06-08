class AddProjectStateIdToProjectAttachments < ActiveRecord::Migration[6.0]
  def change
    add_belongs_to :project_attachments, :workflow_project_state, foreign_key: true
  end
end
