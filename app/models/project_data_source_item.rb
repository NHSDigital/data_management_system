# This is the ProjectDataSourceItem model
# TODO: This model is deprecated (it was replaced by ProjectNode) and should be removed.
class ProjectDataSourceItem < ApplicationRecord
  belongs_to :project
  belongs_to :data_source_item
  has_many :comments, dependent: :destroy

  # Allows a ProjectDataSourceItem to
  # be sorted by DataSourceItem.name
  delegate :name, to: :data_source_item
  delegate :governance, to: :data_source_item

  # need to get a 'default' comment when creating new item
  attr_accessor :comment

  # Allow for auditing/version tracking of ProjectDataSourceItem
  has_paper_trail

  # Hightight Approval status
  # based on it's Governance
  # def approval_highlighting
  #   case approved
  #     when true then 'success'
  #   when false then 'danger'
  #     else 'default'
  #   end
  # end

  delegate :data_items_approved, to: :project, prefix: true # project_data_items_approved
  delegate :can_submit_approvals, to: :project, prefix: true # project_can_submit_approvals

  def comment

  end
end
