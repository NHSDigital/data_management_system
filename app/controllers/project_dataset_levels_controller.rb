# This controller RESTfully manages Project Dataset Level
class ProjectDatasetLevelsController < ApplicationController
  load_and_authorize_resource :project
  load_and_authorize_resource :project_dataset_level

  before_action :challenge_yubikey, only: :approve, if: :yubikey_protected_transition?

  respond_to :js, :html

  def approve
    @project_dataset_level.update(project_dataset_level_params)
  end

  def reject
    @project_dataset_level.update(project_dataset_level_params)
  end

  def reapply
    # TODO: expiry_date definitely needs to be input by user for level 1 and extra datasets
    # added as a stop gap for now
    ProjectDatasetLevel.create(project_dataset_id: @project_dataset_level.project_dataset_id,
                               access_level_id: @project_dataset_level.access_level_id,
                               expiry_date: 1.year.from_now,
                               selected: true, current: true)
  end

  def renew
    expiry_date = project_dataset_level_params['expiry_date'].presence || 1.year.from_now

    ProjectDatasetLevel.create(project_dataset_id: @project_dataset_level.project_dataset_id,
                               access_level_id: @project_dataset_level.access_level_id,
                               expiry_date: expiry_date, selected: true, current: true)
  end

  private

  def project_dataset_level_params
    params.fetch(:project_dataset_level, {}).permit(:id, :approved, :decided_at, :expiry_date)
  end

  def yubikey_protected_transition?
    Rails.env.development? ? false : true
  end
end
