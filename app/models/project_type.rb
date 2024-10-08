class ProjectType < ApplicationRecord
  has_many :projects

  has_many :project_type_datasets, inverse_of: :project_type, dependent: :destroy
  has_many :datasets, through: :project_type_datasets, dependent: :destroy

  scope :available,     -> { where.not(name: 'Application') }
  scope :application,   -> { where(name: 'Application') }
  scope :eoi,           -> { where(name: 'EOI') }
  scope :project,       -> { where(name: 'Project') }
  scope :cas,           -> { where(name: 'CAS') }
  scope :odr,           -> { eoi.or(application) }
  scope :bound_to_team, -> { where.not(name: 'CAS') }
  scope :odr_mbis, -> { where(name: %w[Project EOI Application]) }

  class << self
    # Scopes `ProjectType` to those most relevant to a given user, in certain use cases (e.g. for
    # the projects dashboard page).
    # TODO: Given changes/improvements(?) to project filtering, is this still required?
    def pertinent_to_user_role(user)
      return odr_mbis if user.odr? || user.application_manager? || user.senior_application_manager?
      return project  if user.mbis_delegate? || user.mbis_applicant?

      all
    end
  end

  def translated_name
    I18n.t(to_lookup_key, scope: model_name.plural)
  end

  # TODO: Extract to a concern?
  def to_lookup_key
    name.parameterize(separator: '_').to_sym
  end

  def supports_pdf_import?
    name == 'Application'
  end

  def available_datasets
    datasets.empty? ? published_datasets : datasets
  end

  # TODO: When there's more time this should probably be done through cancan.
  def self.by_team_and_user_role(team, user)
    return ProjectType.all if user.application_manager?

    project_types = []

    project_types << 'Project' if applicant_for_team(user, team, TeamRole.fetch(:mbis_applicant))
    project_types += %w[EOI Application CAS] if
      applicant_for_team(user, team, TeamRole.fetch(:odr_applicant))

    where(name: project_types)
  end

  def self.applicant_for_team(user, team, roleable)
    user.grants.where(roleable: roleable, team_id: team).present?
  end

  def published_datasets
    Dataset.odr.each_with_object([]) do |dataset, published|
      published << dataset if dataset.dataset_versions.any?(&:published)
    end
  end
end
