# Controller for managing role grants across MBIS.
class TeamGrantsController < ApplicationController
  load_and_authorize_resource :user

  # Authorise the parent resource, @user, for :edit_grants instead of the default :read
  before_action :authorize_user_for_editing, except: [:index]

  # Load grants through user, we'll authorize each grant individually:
  load_resource :grant, through: :user


  def index
    redirect_to "/teams/#{params[:team_id]}"
  end

  def update
    if perform_authorized_grant_updates!(grant_matrix)
      flash[:notice] = 'Team grants updated.'
      redirect_to "/teams/#{@team.id}#!users"
    else
      flash.now[:alert] = 'Cannot remove all grants!'
      render :index
    end
  end

  def edit
    @roles = TeamRole.all
    @users = User.search(params: search_params).
             includes(grants: :roleable).
             select(:id, :first_name, :last_name, :email).
             order(:last_name, :first_name).
             paginate(page: params[:page], per_page: 20)

    @grant = Grant.new(team_id: params[:team_id], roleable: TeamRole.fetch(:read_only))
    @team = Team.find(params[:team_id])
  end

  private

  def search_params
    params.fetch(:user_search, {}).permit(:first_name, :last_name, :email)
  end

  def grant_matrix
    TeamGrantMatrix.new(params).call
  end

  def authorize_user_for_editing
    @user ||= current_user
    authorize!(:edit_grants, @user)
  end

  def perform_authorized_grant_updates!(clean_hash)
    number_of_grants = nil
    @team = Team.find(clean_hash[:team_id])
    @team.transaction do
      clean_hash[:users].each do |user_id, roles|
        roles.each do |role, granted|
          init_options = { roleable: TeamRole.find(role), user_id: user_id}
          grant = @team.grants.find_or_initialize_by(init_options)
          authorize!(:toggle, grant)

          if granted
            grant.save! unless grant.persisted?
          else
            grant.destroy! if grant.persisted?
          end
        end
      end

      @team.reload
      number_of_grants = @team.grants.count

      raise ActiveRecord::Rollback if number_of_grants.zero?
    end

    number_of_grants.positive?
  end
end
