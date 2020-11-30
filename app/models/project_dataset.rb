# TeamDataSource associations and validations
# If ODR EOI's and Applications are a choice of every single dataset, do we even need this anymore?
# It will only exist to limit an MBIS team to 1 of the 4 MBIS dataset. Any point?
class ProjectDataset < ApplicationRecord
  belongs_to :project
  belongs_to :dataset

  has_many :approver_grants, lambda {
    joins(:datasets).where grants: { roleable_type: 'DatasetRole', roleable_id: DatasetRole.fetch(:approver).id }
  }, class_name: 'Grant'
  has_many :approvers, through: :approver_grants, class_name: 'User', source: :user

  # Allow for auditing/version tracking of TeamDataSource
  has_paper_trail

  # TODO approved only applies to CAS so far

  scope :outstanding_approval, lambda { |user|
    joins(dataset: :grants).where(
      approved: nil,
      grants: { user_id: user.id,
                roleable_type: 'DatasetRole',
                roleable_id: DatasetRole.fetch(:approver).id }
    )
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

  after_update :auto_transition_application

  # TODO: TEST
  def terms_accepted_for_dataset
    return if dataset.nil?
    return if dataset.dataset_type_name == 'cas'
    return if terms_accepted

    errors.add(:project_dataset, "Terms accepted can't be blank")
  end

  # TODO test this!
  def auto_transition_application
    return unless project.cas?
    return if project.project_datasets.any? { |project_dataset| project_dataset.approved.nil? }

    project.transition_to!(Workflow::State.find('AWAITING_ACCOUNT_APPROVAL'))
  end
end
