# Model for User, Team & Project grants
class Grant < ApplicationRecord
  belongs_to :roleable, polymorphic: true
  belongs_to :user

  belongs_to :team, foreign_key: :team_id, optional: true
  belongs_to :project, foreign_key: :project_id, optional: true
  belongs_to :dataset, foreign_key: :dataset_id, optional: true

  scope :teams, -> { where.not(team_id: nil) }
  scope :projects, -> { where.not(project_id: nil) }
  scope :datasets, -> { where.not(dataset_id: nil) }
  scope :without_project_owner, -> { projects.where.not(roleable: ProjectRole.owner) }
  scope :contributors, -> { projects.where(roleable: ProjectRole.fetch(:contributor))}
  # TODO: robust enough?
  scope :systems, -> { where(team_id: nil, project_id: nil, dataset_id: nil) }
  scope :odr, -> { where(roleable: SystemRole.find_by(name: 'ODR')) }

  validates :project_id, uniqueness: { scope: %i[user_id roleable_id],
                                       message: 'already has this project grant!' }, allow_nil: true

  validates :team_id, uniqueness: { scope: %i[user_id roleable_id],
                                    message: 'already has this team grant!' }, allow_nil: true

  validates :dataset_id, uniqueness: { scope: %i[user_id roleable_id],
                                       message: 'already has this dataset grant!' }, allow_nil: true

  delegate :full_name, to: :user, prefix: false, allow_nil: true

  has_paper_trail
  
  # TODO: Change previous owner to contributor
  # TODO: on create, if picking a different owner to current user, current user should get contributor
  after_save :remove_current_owner_as_contributor
  after_save :add_previous_owner_as_contributor
  
  def add_previous_owner_as_contributor
    return unless previous_changes['user_id']
    # created from scatch. no previous owner
    return if previous_changes['user_id'].first.nil?
    return unless roleable == ProjectRole.fetch(:owner)

    project.add_previous_owner_as_contributor(previous_changes['user_id'].first)
  end
  
  def remove_current_owner_as_contributor
    return unless previous_changes['user_id'] 
    # created from scatch. nothing to remove
    return if previous_changes['user_id'].first.nil?
    return unless roleable == ProjectRole.fetch(:owner)

    project.remove_current_owner_as_contributor(previous_changes['user_id'].last)
  end
  # after_save do
  #   binding.pry
  #   return unless previous_changes['user_id'] && roleable == ProjectRole.fetch(:owner)
  #
  #   project.add_previous_owner_as_contributor(previous_changes['user_id'].first)
  # end
end
