# This controller RESTfully manages Project Dataset Level
class ProjectDatasetLevelsController < ApplicationController
  load_and_authorize_resource :project
  load_and_authorize_resource :project_dataset_level

  before_action :challenge_yubikey, only: :approve, if: :yubikey_protected_transition?

  respond_to :js, :html

  def update
    @project_dataset_level.update(project_dataset_level_params)
  end

  def approve
    @project_dataset_level.update(project_dataset_level_params)
  end

  def reapply
    @project_dataset_level.update(project_dataset_level_params)
  end

  private

  def project_dataset_level_params
    params.fetch(:project_dataset_level, {}).permit(:id, :approved)
  end

  def yubikey_protected_transition?
    Rails.env.development? ? false : true
  end
end
