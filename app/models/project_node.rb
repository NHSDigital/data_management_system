# This is the ProjectDataSourceItem model
class ProjectNode < ApplicationRecord
  include Commentable

  belongs_to :project
  belongs_to :node

  # Allows a ProjectDataSourceItem to
  # be sorted by DataSourceItem.name
  delegate :name, to: :node
  delegate :governance, to: :node

  # Allow for auditing/version tracking of ProjectDataSourceItem
  has_paper_trail

  delegate :data_items_approved, to: :project, prefix: true # project_data_items_approved
  delegate :can_submit_approvals, to: :project, prefix: true # project_can_submit_approvals
end
