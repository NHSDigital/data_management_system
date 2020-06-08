# This controller RESTfully manages Project Data End Users
class ProjectDataEndUsersController < ApplicationController
  load_and_authorize_resource :project
  load_and_authorize_resource :project_data_end_user, through: :project, shallow: true

  respond_to :js, :html

  def new
  end

  # POST /project_memberships
  def create
    message = "#{@project_data_end_user.first_name + ' ' + @project_data_end_user.last_name} successfully added to " \
              "#{@project_data_end_user.project.name}."
    if @project_data_end_user.save
      js_partial = 'create'
      if @project.submitted?
        flash[:notice] = message
        flash.keep(:notice)
        js_partial = '/projects/reload' # force page reload but losing message
      end
      respond_to do |format|
        format.html { redirect_to @project_data_end_user.project, notice: message }
        format.js do
          render js_partial
        end
      end
    else
      render :new
    end
  end

  # DELETE /project_memberships/1
  def destroy
    if @project_data_end_user.destroy
      ui_destroy
    else
      error_message = 'Cannot remove the data user '
      respond_to do |format|
        format.html { redirect_to @project_data_end_user.project, alert: error_message }
        format.js { render js: "alert('#{error_message}')" }
      end
    end
  end

  private

  # Remove the row from the
  # list of project memberships
  def ui_destroy
    respond_to do |format|
      format.js do
        render js:  %( jQuery("##{dom_id(@project_data_end_user)}").hide('fast') )
      end
    end
  end

  # Only allow a trusted parameter "white list" through.
  def project_data_end_user_params
    params.require(:project_data_end_user).permit(:first_name, :last_name, :email, :ts_cs_accepted)
  end
end
