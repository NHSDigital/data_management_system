# This controller RESTfully manages Project Dataset
class ProjectDatasetsController < ApplicationController
  load_and_authorize_resource :project
  load_and_authorize_resource :project_dataset, through: :project, shallow: true

  before_action :challenge_yubikey, only: :approve

  respond_to :js, :html

  def update
    @project_dataset.update(project_dataset_params)
  end

  def approve
    @project_dataset.update(project_dataset_params)
  end

  private

  def project_dataset_params
    params.fetch(:project_dataset, {}).permit(:id, :approved)
  end
end
