# This controller RESTfully manages Project Memberships
class ProjectMembershipsController < ApplicationController
  load_and_authorize_resource :project
  load_and_authorize_resource :project_membership, through: :project, shallow: true

  respond_to :js, :html

  def new
  end

  # POST /project_memberships
  def create
    message = "#{@project_membership.membership.member_full_name} successfully added to " \
              "#{@project_membership.project_name}."
    message += ' The project status has been set to New' if @project_membership.project.submitted?
    if @project_membership.save
      respond_to do |format|
        format.html { redirect_to @project_membership.project, notice: message }
        format.js
      end
      # send mail
    else
      render :new
    end
  end

  # DELETE /project_memberships/1
  def destroy
    if @project_membership.destroy
      ui_destroy
    else
      error_message = 'Cannot remove the Project membership:' \
                      " #{@project_membership.membership.member_full_name} is the senior user"
      respond_to do |format|
        format.html { redirect_to @project_membership.project, alert: error_message }
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
        render js:  %( jQuery("##{dom_id(@project_membership)}").hide('fast') )
      end
    end
  end

  # Only allow a trusted parameter "white list" through.
  def project_membership_params
    params.require(:project_membership).permit(:membership_id)
  end
end
