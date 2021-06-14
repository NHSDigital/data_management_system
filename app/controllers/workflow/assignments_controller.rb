module Workflow
  # RESTfully manages `User` assignments to a given `ProjectState`
  class AssignmentsController < ApplicationController
    load_and_authorize_resource :project_state
    load_and_authorize_resource through: :project_state, shallow: true

    before_action :redirect_unless_current_state

    def create
      @assignment.assigning_user = current_user
      @assignment.assigned_user  = assignable_users.find_by(id: @assignment.assigned_user_id)

      if @assignment.save
        ProjectsMailer.with(
          project:     @assignment.project,
          assigned_to: @assignment.assigned_user,
          assigned_by: @assignment.assigning_user
        ).project_assignment.deliver_later

        redirect_to @project_state.project, notice: 'Project assigned successfully'
      else
        redirect_to @project_state.project, alert: 'Could not assign project!'
      end
    end

    private

    def redirect_unless_current_state
      project = @assignment.project
      current_project_state = project.current_project_state

      redirect_to project unless @project_state.id == current_project_state.id
    end

    def resource_params
      params.fetch(:assignment, {}).permit(:assigned_user_id)
    end

    def assignable_users
      @project_state.assignable_users
    end
  end
end
