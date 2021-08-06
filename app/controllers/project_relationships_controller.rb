# RESTfully manages creating/deleting `ProjectRelationship`s
class ProjectRelationshipsController < ApplicationController
  load_and_authorize_resource :project
  load_and_authorize_resource :team, through: :project, singleton: true
  load_and_authorize_resource through: :project, only: %i[create destroy]

  def index
    authorize!(:read, ProjectRelationship)

    @projects = @team.projects.
                accessible_by(current_ability).
                where.not(id: @project).
                search(search_params).
                order_by_reference.
                includes(:project_type, :owner, :current_state).
                paginate(page: params[:page], per_page: 10)
  end

  def create
    @project_relationship.assign_attributes(
      left_project:  @project,
      right_project: @team.projects.find_by(id: resource_params[:right_project_id])
    )

    @project_relationship.save

    options =
      if @project_relationship.persisted?
        { notice: t('.success') }
      else
        { alert: t('.failure') }
      end

    redirect_to after_action_path, options
  end

  def destroy
    @project_relationship.destroy

    options =
      if @project_relationship.destroyed?
        { notice: t('.success') }
      else
        { alert: t('.failure') }
      end

    redirect_to after_action_path, options
  end

  private

  def resource_params
    params.require(:project_relationship).permit(:right_project_id)
  end

  def search_params
    params.fetch(:search, {}).permit(
      :name,
      :application_log,
      project_type_id: [],
      owner: %i[
        first_name
        last_name
      ],
      current_project_state: {
        state_id: []
      }
    )
  end
  helper_method :search_params

  def after_action_path
    project_project_relationships_path(@project, search: search_params)
  end
end
