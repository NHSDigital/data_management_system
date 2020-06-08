# Controller for managing role grants to Projects.
class ProjectGrantsController < ApplicationController
  load_and_authorize_resource :user

  # Authorise the parent resource, @user, for :edit_grants instead of the default :read
  before_action :authorize_user_for_editing, except: [:index]

  # Load grants through user, we'll authorize each grant individually:
  load_resource :grant, through: :user

  def index
    redirect_to "/projects/#{params[:project_id]}#!users"
  end
  
  def update
    if perform_authorized_grant_updates!(grant_matrix)
      flash[:notice] = 'Project grants updated.'
      redirect_to "/projects/#{@project.id}#!users"
    else
      flash.now[:alert] = 'Cannot remove all grants!'
      redirect_to "/projects/#{@project.id}#!users"
    end
  end
  
  def edit
    @project = Project.find(params[:project_id])
    @team = @project.team
    @grant = Grant.new(project_id: @project.id, roleable: ProjectRole.fetch(:read_only))
  end

  private

  def grant_matrix
    # TODO: Rename/Share this model
    ProjectGrantMatrix.new(params).call
  end

  def authorize_user_for_editing
    @user ||= current_user
    authorize!(:edit_grants, @user)
  end

  def perform_authorized_grant_updates!(clean_hash)
    number_of_grants = nil
    @project = Project.find(clean_hash[:project_id])
    @project.transaction do
      clean_hash[:users].each do |user_id, roles|
        roles.each do |role, granted|
          init_options = { roleable: ProjectRole.find(role), user_id: user_id}
          grant = @project.grants.find_or_initialize_by(init_options)
          authorize!(:toggle, grant)
          if granted
            grant.save! unless grant.persisted?
          else
            grant.destroy! if grant.persisted?
          end
        end
      end

      @project.reload
      number_of_grants = @project.grants.count

      raise ActiveRecord::Rollback if number_of_grants.zero?
    end

    number_of_grants.positive?
  end
end
