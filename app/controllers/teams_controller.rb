# This controller RESTfully manages teams
class TeamsController < ApplicationController
  load_and_authorize_resource :organisation
  load_and_authorize_resource through: :organisation, shallow: true

  respond_to :js, :html

  def new; end

  # TODO: is active team still active?! causing a problem in tests
  def index
    @teams =
      if current_user.system_user?
        Team.all.active
      else
        current_user.teams
      end
    @teams = @teams.search(@teams, search_params).paginate(page: params[:page], per_page: 15).
             order(updated_at: :desc)
  end

  def show
    warning = 'Please activate team before creating projects' if @team.z_team_status_name == 'New'
    flash.now[:warning] = warning
    @readonly = true
    if params[:project_types] == 'not_in_use'
      @projects = @team.projects.not_in_use
    else
      @projects = @team.projects.in_use
    end
  end

  def edit; end

  # POST /teams
  def create
    if @team.save
      redirect_to @team, notice: 'Team was successfully created, please add team members ' \
                                 'and set team to active'
    else
      render :new
    end
  end

  # PATCH/PUT /teams/1
  def update
    # doing it this way so we can catch changes applied (for notification)
    # TODO : track association changes before we save it
    @team.assign_attributes(team_params)
#    team_changes = @team.changes.collect { |a, b| "#{a} changed from '#{b[0]}' to '#{b[1]}'" }.join("\n\n")
#    if @team.z_team_status_id_was == ZTeamStatus.where(name: 'New').first.id &&
#       @team.z_team_status_id == ZTeamStatus.where(name: 'Active').first.id
#      new_notification = true
#    end

    if @team.save
#      new_notification ? @team.new_team_notification : @team.edit_team_notification(team_changes)

      respond_to do |format|
        format.html { redirect_to @team, notice: 'Team was successfully updated.' }
        format.js { render :update }
      end
    else
      render :edit
    end
  end

  # DELETE /teams/1
  def destroy
    if @team.projects.active.any?
      redirect_to @team, alert: 'Team still has active projects so has not been deleted'
    else
      @destroyed = @team.update(z_team_status: ZTeamStatus.where(name: 'Deleted').first)
      respond_to do |format|
        format.js
        format.html do
          if @destroyed
            redirect_to organisation_teams_url(@team.organisation), notice: 'Team was successfully destroyed.'
          else
            redirect_to organisation_teams_url(@team.organisation), notice: 'Team cannot be destroyed.'
          end
        end
      end
    end
  end

  private

  # Only allow a trusted parameter "white list" through.
  def team_params
    params.require(:team).permit(:name, :z_team_status_id, :notes,
                                 :directorate_id, :division_id,
                                 data_source_ids: [],
                                 member_ids: [],
                                 delegate_user_ids: [],
                                 memberships_attributes: %i[id _destroy user_id senior],
                                 addresses_attributes: %i[id add1 add2 postcode telephone
                                                          country_id city telephone _destroy])
  end

  def search_params
    params.fetch(:search, {}).permit(:name)
  end
end
