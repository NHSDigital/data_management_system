# TeamDataSource associations and validations
# If ODR EOI's and Applications are a choice of every single dataset, do we even need this anymore?
# It will only exist to limit an MBIS team to 1 of the 4 MBIS dataset. Any point?
class ProjectDataset < ApplicationRecord
  belongs_to :project
  belongs_to :dataset

  has_many :approver_grants, lambda {
    joins(:datasets).where grants: { roleable_type: 'DatasetRole',
                                     roleable_id: DatasetRole.fetch(:approver).id }
  }, class_name: 'Grant'
  has_many :approvers, through: :approver_grants, class_name: 'User', source: :user
  has_many :project_dataset_levels, dependent: :destroy
  accepts_nested_attributes_for :project_dataset_levels

  # Allow for auditing/version tracking of TeamDataSource
  has_paper_trail

  # TODO: approved only applies to CAS so far

  scope :dataset_approval, lambda { |user, approved_values = [nil, true, false]|
    joins(dataset: :grants).where(
      grants: { user_id: user.id,
                roleable_type: 'DatasetRole',
                roleable_id: DatasetRole.fetch(:approver).id }
    ).joins(:project_dataset_levels).where(project_dataset_levels: { approved: approved_values })
  }

  # data_source_name
  delegate :name, to: :dataset, prefix: true
  delegate :full_name, to: :dataset, prefix: true
  delegate :terms, to: :dataset, prefix: true

  # team_name
  delegate :name, to: :project, prefix: true

  validates :dataset_id, uniqueness: { scope: [:project_id],
                                       message: 'Project already has access ' \
                                                'to this dataset' }

  validate :terms_accepted_for_dataset

  before_save :destroy_project_dataset_levels_without_selected

  # TODO: TEST
  def terms_accepted_for_dataset
    return if dataset.nil?
    return if dataset.cas_type
    return if terms_accepted

    errors.add(:project_dataset, "Terms accepted can't be blank")
  end

  def destroy_project_dataset_levels_without_selected
    return unless project.cas?
    return unless project_dataset_levels.any?

    not_selected = project_dataset_levels.select do |pdl|
      pdl.selected == false
    end

    self.project_dataset_levels = (project_dataset_levels - not_selected)
  end
end
