# This controller RESTfully manages the Active Team
class ActiveTeamController < ApplicationController
  before_action :warn_against_no_team_membership
  before_action :set_active_team_if_possible

  def index
  end

  def update
    @team = current_user.teams.find(params[:id])
    authorize!(:read, @team)

    session[:current_team] = @team.id
    redirect_to root_path, notice: "Current team has been set to: #{@team.name}"
  end

  def set_active_team_if_possible
    return unless current_user.teams.count == 1
    session[:current_team] = current_user.teams.first.id
    message = "Current team has been set to: #{current_user.teams.first.name}"
    redirect_to root_path, notice: message
  end

  def warn_against_no_team_membership
    return if current_user.teams?
    flash[:notice] = 'You are not currently a member of any team. Please contact
                      an Administrator or Team Senior User to be added to a Team'
  end
end
