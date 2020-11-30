# This controller RESTfully manages Project Dataset
class ProjectDatasetsController < ApplicationController
  load_and_authorize_resource :project
  load_and_authorize_resource :project_dataset, through: :project, shallow: true

  respond_to :js, :html

  def update
    @project_dataset.update(project_dataset_params)
  end

  private

  def project_dataset_params
    params.require(:project_dataset).permit(:id, :approved)
  end
end
