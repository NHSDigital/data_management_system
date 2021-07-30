class PopulateProjectRelationshipsForExistingProjects < ActiveRecord::Migration[6.0]
  class ProjectRelationship < ApplicationRecord; end

  class ProjectType < ApplicationRecord
    scope :odr, -> { where(name: %w[Application EOI]) }
  end

  class Project < ApplicationRecord
    belongs_to :project_type
  end

  def up
    pairs = projects_in_scope.pluck(:id, :clone_of)

    # Ensure only unique pairs
    pairs.map!(&:sort)
    pairs.uniq!

    pairs.each do |left, right|
      next if left == right

      ProjectRelationship.create!(
        left_project_id:  left,
        right_project_id: right
      )
    end
  end

  # Do nothing.
  def down; end

  private

  def projects_in_scope
    Project.joins(:project_type).
      merge(ProjectType.odr).
      where.not(clone_of: nil)
  end
end
