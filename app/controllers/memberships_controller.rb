# This controller RESTfully manages Team Memberships
class MembershipsController < ApplicationController
  load_and_authorize_resource :team
  load_and_authorize_resource :membership, through: :team, shallow: true

  respond_to :js, :html

  def index
  end

  def show
    # The user doesn't need to see
    # an individual membership
    redirect_to @membership.team
  end

  def new
  end

  # POST /memberships
  def create
    if @membership.save
      message = "#{@membership.member_full_name} successfully added to " \
                "#{@membership.team_name}"
      if @membership.team.z_team_status_name == 'Active'
        @membership.team.edit_team_notification("Team member #{@membership.member.full_name} " \
                                                "added to team #{@membership.team.name}")
      end
      respond_to do |format|
        format.html { redirect_to @membership.team, notice: message }
        format.js { render :index }
      end
      # send mail
    else
      render :new
    end
  end

  def edit
  end

  # PATCH/PUT /memberships/1
  def update
    if @membership.update(membership_params)
      message = "#{@membership.member_full_name}'s #{@membership.team_name} " \
                'membership successfully updated'

      respond_to do |format|
        format.html { redirect_to @membership.team, notice: message }
        format.js { render :index }
      end
    else
      render :edit
    end
  end

  # DELETE /memberships/1
  def destroy
    msg = "Team Member #{@membership.member.full_name} removed from team #{@membership.team.name}"
    if current_users_current_team?
      redirect_to team_url(@membership.team), alert: "Can't remove yourself from your current Team"
    elsif @membership.destroy
      @membership.team.edit_team_notification(msg) if @membership.team.z_team_status_name == 'Active'
      ui_destroy
    else
      error_message = "Cannot be removed from Team: #{@membership.member_full_name}" \
                      " is the senior user in project(s): #{@membership.senior_user_project_names}"
      respond_to do |format|
        format.html { redirect_to @membership.team, alert: error_message }
        format.js { render js: "alert('#{error_message}')" }
      end
    end
  end

  private

  def ui_destroy
    respond_to do |format|
      format.html do
        redirect_to team_url(@membership.team),
                    notice: 'Member was successfully removed from Team.'
      end
      format.js do
        #render js:  %( jQuery("##{dom_id(@membership)}").hide('fast') )
        render :index
      end
    end
  end

  def current_users_current_team?
    @membership.member == current_user && @membership.team == current_team
  end

  # Only allow a trusted parameter "white list" through.
  def membership_params
    params.require(:membership).permit(:senior, :user_id, :team_id)
  end
end
