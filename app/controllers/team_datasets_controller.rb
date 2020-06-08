# This controller RESTfully manages a Team's data soucres
class TeamDatasetsController < ApplicationController
  load_and_authorize_resource :team
  load_and_authorize_resource :team_dataset, through: :team, shallow: true

  respond_to :js, :html

  def show
    # The user doesn't need to see
    # an individual team_data_source
    redirect_to @team
  end

  def new
  end

  def index
    # The user doesn't need to see #index
    redirect_to @team
  end

  # POST /team_data_sources
  def create
    if @team_dataset.save
      message = "#{@team_dataset.dataset.name} successfully added to " \
                "#{@team_dataset.team.name}"
      if 'Active' == @team_dataset.team.z_team_status_name
        notification_message = "Dataset #{@team_dataset.dataset.name} " \
                               "added to team #{@team_dataset.team_name}"
        @team.edit_team_notification(notification_message)
      end

      respond_to do |format|
        format.html { redirect_to @team_dataset.team, notice: message }
        format.js
      end
      # send mail
    else
      render :new
    end
  end

  # DELETE /team_data_sources/1
  def destroy
    msg = "Dataset #{@team_dataset.dataset.name} " \
          "removed from team #{@team_dataset.team.name}"
    if @team_dataset.destroy
      @team_dataset.team.edit_team_notification(msg)
      ui_destroy
    else
      error_message = "Can not remove #{@team_dataset.dataset.name} - currently in use"

      respond_to do |format|
        format.html { redirect_to @team_dataset.team, alert: error_message }
        format.js { render js: "alert('#{error_message}')" }
      end
    end
  end

  private

  # Remove the team data source row on screen
  def ui_destroy
    @team = @team_dataset.team
    respond_to do |format|
      format.html do
        redirect_to team_url(@team_dataset.team),
                    notice: 'Data Source was successfully removed from Team.'
      end
      format.js do
        #render js:  %( jQuery("##{dom_id(@team_data_source)}").hide('fast') )
        render :create
      end
    end
  end

  # Only allow a trusted parameter "white list" through.
  def team_dataset_params
    params.require(:team_dataset).permit(:dataset_id)
  end
end
