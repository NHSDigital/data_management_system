# Model for the ProjectDatasetLevel class
class ProjectDatasetLevel < ApplicationRecord
  belongs_to :project_dataset
  delegate :project, to: :project_dataset
  after_create :set_expiry_date_to_one_year
  after_create :set_status_to_requested_on_create
  after_update :set_decided_at_to_nil
  after_update :notify_cas_approved_change

  validate :expiry_date_must_be_present_for_level_one_or_extra_datasets
  validate :must_be_future_expiry_date, on: :create
  validates :status, uniqueness: { scope: %i[access_level_id project_dataset_id] },
                     if: proc { |pdl| %w[request approved renewable].include?(pdl.status) }

  enum status: { request: 1, approved: 2, rejected: 3, renewable: 4, closed: 5 }

  scope :same_access_level_levels, lambda { |pdl|
    where(project_dataset_id: pdl.project_dataset_id, access_level_id: pdl.access_level_id).
      where.not(id: pdl.id)
  }

  scope :same_project, lambda { |project|
    joins(:project_dataset).where(project_datasets: { project_id: project.id })
  }

  scope :cas_type_levels, lambda { |project, cas_type|
    joins(:project_dataset).where(project_datasets: { project_id: project.id }).
      joins(project_dataset: :dataset).where(datasets: { cas_type: cas_type })
  }

  scope :default_level_2_3_bulk_approvable, lambda { |project, user|
    request.where(access_level_id: [2, 3]).
      joins(:project_dataset).where(project_datasets: { project_id: project.id }).
      joins(project_dataset: :dataset).where(datasets: { cas_type: 1 }).
      joins(project_dataset: { project: :current_state }).
      merge(Workflow::State.dataset_approval_states).
      joins(project_dataset: { dataset: :grants }).where(
        grants: { user_id: user.id,
                  roleable_type: 'DatasetRole',
                  roleable_id: DatasetRole.fetch(:approver).id }
      )
  }

  scope :default_level_2_3_bulk_renew_request, lambda { |project, user|
    renewable.where(access_level_id: [2, 3]).
      joins(:project_dataset).where(project_datasets: { project_id: project.id }).
      joins(project_dataset: :dataset).where(datasets: { cas_type: 1 }).
      joins(project_dataset: { project: :grants }).where(
        grants: { user_id: user.id,
                  roleable_type: 'ProjectRole',
                  roleable_id: ProjectRole.fetch(:owner).id }
      )
  }

  def selected?
    selected
  end

  # show if last rejected and none in requested
  def reappliable?
    ProjectDatasetLevel.rejected.where(project_dataset_id: project_dataset.id,
                                       access_level_id: access_level_id).
      max_by(&:created_at) == self &&
      ProjectDatasetLevel.same_access_level_levels(self).request.none?
  end

  def level_2_3_default?
    project_dataset.dataset.cas_defaults? && [2, 3].include?(access_level_id)
  end

  def level_1_default?
    project_dataset.dataset.cas_defaults? && access_level_id == 1
  end

  def notify_cas_approved_change
    return unless project.cas?
    # Should only be approving after DRAFT
    return if project.reload.current_state&.id == 'DRAFT'
    return if request?

    User.cas_manager_and_access_approvers.each do |user|
      CasNotifier.dataset_level_approved_status_updated(project, self, user.id)
    end
    CasMailer.with(project: project, project_dataset_level: self).send(
      :dataset_level_approved_status_updated
    ).deliver_later

    approved_change_to_user
  end

  def set_expiry_date_to_one_year
    return unless project.cas?
    return unless level_2_3_default?

    update_column(:expiry_date, 1.year.from_now)
  end

  def set_status_to_requested_on_create
    update_column(:status, :request)
  end

  def expiry_date_must_be_present_for_level_one_or_extra_datasets
    return unless project.cas?
    return unless selected?
    return unless access_level_id == 1 || project_dataset.dataset.cas_extras?
    return if expiry_date.present?

    errors.add :expiry_date, :must_have_expiry_date
  end

  def readable_approved_status
    return 'Undecided' if request?
    return 'Approved' if approved?

    'Rejected'
  end

  def must_be_future_expiry_date
    return if expiry_date.blank?
    return unless expiry_date < Time.zone.today

    errors.add(:expiry_date, 'Must be in the future')
  end

  private

  def approved_change_to_user
    CasNotifier.dataset_level_approved_status_updated_to_user(project, self)
    CasMailer.with(project: project, project_dataset_level: self).send(
      :dataset_level_approved_status_updated_to_user
    ).deliver_later
  end

  def set_decided_at_to_nil
    return unless request?

    self.decided_at = nil
  end
end
