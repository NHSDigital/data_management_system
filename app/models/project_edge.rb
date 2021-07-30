# Helper class built upon a view over the `project_relationships` table, which pivots those records
# into something a little easier to query because:
# - managing a join model is easy.
# - querying both sides of a join table because a resource may exist on either FK is hard.
# - querying an adjaceny list is easy.
# - managing adjaceny lists for inverse pairs of records via ActiveRecord callbacks is like
#   sticking your head inside an aligator's mouth; it's all good until it inevitably bites.
class ProjectEdge < ApplicationRecord
  belongs_to :project_relationship
  belongs_to :project
  belongs_to :related_project, class_name: 'Project'

  # This model is backed by a database view.
  def readonly?
    true
  end
end
