# Join model representing some relationship between two `Project`s.
class ProjectRelationship < ApplicationRecord
  with_options class_name: 'Project' do
    belongs_to :left_project
    belongs_to :right_project
  end

  has_many :project_edges, inverse_of: :project_relationship # rubocop:disable Rails/HasManyOrHasOneDependent
  has_many :projects, through: :project_edges, source: :related_project

  validate :no_inverse_pairs
  validate :no_self_referential_relationships

  private

  def no_inverse_pairs
    return unless left_project_id && right_project_id

    return unless
      self.class.where(
        left_project_id:  left_project_id,
        right_project_id: right_project_id
      ).
      or(
        self.class.where(
          left_project_id:  right_project_id,
          right_project_id: left_project_id
        )
      ).
      exists?

    errors.add(:base, :taken)
  end

  def no_self_referential_relationships
    return unless left_project_id && right_project_id
    return if left_project_id != right_project_id

    errors.add(:base, :self_referential)
  end
end
