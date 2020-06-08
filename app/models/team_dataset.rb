# TeamDataSource associations and validations
class TeamDataset < ApplicationRecord
  has_many :projects
  belongs_to :team
  belongs_to :dataset

  # Allow for auditing/version tracking of TeamDataSource
  has_paper_trail

  # data_source_name
  delegate :name, to: :dataset, prefix: true
  delegate :terms, to: :dataset, prefix: true
  # team_name
  delegate :name, to: :team, prefix: true

  validates :dataset_id, uniqueness: { scope: [:team_id],
                                       message: 'Team already has access ' \
                                                'to this data source' }

  delegate :dataset_versions, to: :dataset

  before_destroy do
    throw(:abort) if team_data_source_in_use?
  end

  # Returns true if the team data source
  # is in use by any of the team's projects
  def team_data_source_in_use?
    team_data_source_ids = team.projects.active.map(&:team_dataset_id)
    team_data_source_ids.include?(id)
  end
end
