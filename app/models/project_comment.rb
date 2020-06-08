# Comments for project - user to store reasons for rejections and subsequent justifications
class ProjectComment < ApplicationRecord
  belongs_to :project
  belongs_to :user
  belongs_to :project_node, optional: true
  after_save :update_project_data_source_items

  COMMENT_TYPES = %w(General MemberRejection DetailRejection LegalRejection DataSourceItemRejection
                     MemberJustification DetailJustification DataSourceItemJustification).freeze

  # Allow for auditing/version tracking of ProjectComment
  has_paper_trail

  scope :details,  -> { where(comment_type: %w(DetailRejection DetailJustification)) }
  scope :members,  -> { where(comment_type: %w(MemberRejection MemberJustification)) }
  scope :legal,  -> { where(comment_type: %w(LegalRejection LegalJustification)) }

  delegate :email, to: :user, prefix: true # user_email

  def update_project_data_source_items
    if comment_type == 'DataSourceItemRejection'
      project_node.update(approved: false)
    elsif comment_type == 'DetailRejection'
      project.update(details_approved: false)
    elsif comment_type == 'MemberRejection'
      project.update(members_approved: false)
    elsif comment_type == 'LegalRejection'
      project.update(legal_ethical_approved: false)
    end
  end
end
