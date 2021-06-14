# Dataset Model
class Dataset < ApplicationRecord
  belongs_to :team
  belongs_to :dataset_type, inverse_of: :datasets
  has_many :dataset_versions, dependent: :destroy
  has_many :project_datasets
  has_many :grants, foreign_key: :dataset_id, dependent: :destroy
  has_many :users, -> { extending(GrantedBy).distinct }, through: :grants

  has_many :approver_grants, lambda {
    where grants: { roleable_type: 'DatasetRole', roleable_id: DatasetRole.fetch(:approver).id }
  }, class_name: 'Grant'
  has_many :approvers, through: :approver_grants, class_name: 'User', source: :user

  delegate :name, to: :dataset_type, prefix: true, allow_nil: true

  enum cas_type: { cas_defaults: 1, cas_extras: 2 }

  DATASET_BROWSER_TYPES = %w[xml non_xml].freeze

  scope :for_browsing, lambda {
    joins(:dataset_type).merge(DatasetType.where(name: DATASET_BROWSER_TYPES))
  }

  scope :table_spec, lambda {
    joins(:dataset_type).merge(DatasetType.where(name: 'table_specification'))
  }

  scope :odr, lambda {
    joins(:dataset_type).merge(DatasetType.where(name: 'odr'))
  }

  scope :cas, lambda {
    joins(:dataset_type).merge(DatasetType.where(name: 'cas'))
  }

  def to_xsd(version)
    dataset_versions.find_by(semver_version: version).to_xsd
  end

  validates :name, uniqueness: { scope: :dataset_type }

  before_destroy do
    throw(:abort) if in_use?
  end

  def in_use?
    dataset_versions.any?(&:in_use?)
  end

  class << self
    def search(params)
      filters = []
      %i[name full_name].each do |field|
        filters << field_filter(field, params[:name])
      end

      filters.compact!
      where(filters.first).or(where(filters.last))
    end

    private

    def field_filter(field, text)
      arel_table[field].matches("%#{text.strip}%") if text.present?
    end
  end
end
