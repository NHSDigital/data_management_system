# TeamDataSource associations and validations
class TeamDataSource < ApplicationRecord
  has_many :projects
  belongs_to :team
  belongs_to :data_source

  # Allow for auditing/version tracking of TeamDataSource
  has_paper_trail

  # data_source_name
  delegate :name, to: :data_source, prefix: true
  delegate :terms, to: :data_source, prefix: true
  # team_name
  delegate :name, to: :team, prefix: true

  validates :data_source_id, uniqueness: { scope: [:team_id],
                                           message: 'Team already has acceess ' \
                                                    'to this data source' }

  before_destroy do
    throw(:abort) if team_data_source_in_use?
  end

  # Returns true if the team data source
  # is in use by any of the team's projects
  def team_data_source_in_use?
    team_data_source_ids = team.projects.active.map(&:team_data_source_id)
    team_data_source_ids.include?(id)
  end
end
