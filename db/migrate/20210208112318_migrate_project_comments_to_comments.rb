class MigrateProjectCommentsToComments < ActiveRecord::Migration[6.0]
  class ProjectComment < ApplicationRecord
    belongs_to :project
    belongs_to :user
    belongs_to :project_node, optional: true
  end

  ProjectComment.reset_column_information
  Comment.reset_column_information

  def up
    ProjectComment.find_each do |project_comment|
      commentable = project_comment.project_node || project_comment.project

      commentable.comments.create!(
        user: project_comment.user,
        body: project_comment.comment,
        metadata: {
          project_comment_id: project_comment.id,
          tags: [project_comment.comment_type]
        },
        created_at: project_comment.created_at,
        updated_at: project_comment.updated_at
      )
    end
  end

  def down; end
end
