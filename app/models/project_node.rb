# This is the ProjectDataSourceItem model
class ProjectNode < ApplicationRecord
  belongs_to :project
  belongs_to :node
  has_many :project_comments, dependent: :destroy

  # Allows a ProjectDataSourceItem to
  # be sorted by DataSourceItem.name
  delegate :name, to: :node
  delegate :governance, to: :node

  # need to get a 'default' comment when creating new item
  attr_accessor :comment

  # Allow for auditing/version tracking of ProjectDataSourceItem
  has_paper_trail

  delegate :data_items_approved, to: :project, prefix: true # project_data_items_approved
  delegate :can_submit_approvals, to: :project, prefix: true # project_can_submit_approvals
end
