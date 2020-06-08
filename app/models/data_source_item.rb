# Defines DataSourceItem associations and validations
class DataSourceItem < ApplicationRecord
  belongs_to :data_source
  has_many :project_data_source_items
  has_many :projects, through: :project_data_source_items

  delegate :name, to: :data_source, prefix: true # data_source_name

  validates :name, presence: true, uniqueness: { scope: [:data_source_id],
                                                 message: 'already in use for this data source' }
  validates :description, presence: true
  validates :governance, presence: true

  # scope :icd, -> { where("name like '%ICD%'") }
  # scope :geo, -> { where("category like '%Location%'") }
  before_destroy do
    throw(:abort) if in_use?
  end

  # zlookup ??
  GOVERNANCES = ['DIRECT IDENTIFIER', 'INDIRECT IDENTIFIER', 'NON IDENTIFYING DATA'].freeze

  # Higtlight DataSourceItem
  # based on it's Governance
  def highlighting
    case governance
    when 'DIRECT IDENTIFIER'   then 'danger'
    when 'INDIRECT IDENTIFIER' then 'warning'
    else 'default'
    end
  end

  def colour
    case governance
    when 'DIRECT IDENTIFIER'   then 'red'
    when 'INDIRECT IDENTIFIER' then 'orange'
    else 'green'
    end
  end

  # Friendly name based on it's Governance
  def identifiable_icon
    case governance
    when 'DIRECT IDENTIFIER'   then 'eye-open icon-danger'
    when 'INDIRECT IDENTIFIER' then 'eye-open icon-warning'
    else 'eye-close icon-success'
    end
  end

  def friendly_name
    governance[0..2] + ': ' + name + ': ' + description[0..40]
  end

  # returns true for any data items
  # currently being used by projects
  def in_use?
    projects.any?
  end
end
