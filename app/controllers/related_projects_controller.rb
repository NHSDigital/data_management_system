# Endpoint for fetching the related projects for a given resource.
class RelatedProjectsController < ApplicationController
  load_and_authorize_resource :project

  def index
    edges    = @project.project_edges.transitive_closure
    projects = Project.where(id: edges.select(:related_project_id)).
               accessible_by(current_user.current_ability)

    locals = {
      projects: projects
    }

    respond_to do |format|
      format.html { render partial: 'projects', locals: locals, content_type: :html }
    end
  end
end
