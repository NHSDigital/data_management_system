# This controller RESTfully manages Project Attachments
class ProjectAttachmentsController < ApplicationController
  load_and_authorize_resource :project
  load_and_authorize_resource :project_attachment, through: :project, shallow: true

  respond_to :js, :html

  def new
  end

  # POST /project_attachments
  def create
    message = "#{@project_attachment.name} successfully added to " \
              "#{@project_attachment.project_name}"
    # need to get right tab to show in ui after create
    tab_name = @project_attachment.name.parameterize

    if @project_attachment.save
      @project_attachment.import_end_users
      respond_to do |format|
        if ['REC Approval Letter', 'Section 251 Exemption' ,'Calidicott Approval Letter'].include? @project_attachment.name
          format.html { redirect_to project_path(@project_attachment.project, anchor: '!legal'), notice: message }
        elsif @project_attachment.name == 'Data End Users'
          message = "Added #{@project_attachment.end_users_added} and updated " \
                    "#{@project_attachment.end_users_updated} end user(s) "
          if @project_attachment.errors.count.positive?
            format.html do
              redirect_to project_path(@project_attachment.project, anchor: '!users'),
                          notice: @project_attachment.errors.full_messages.to_s
            end
          else
            format.html do
              redirect_to project_path(@project_attachment.project, anchor: '!users'),
                          notice: message
            end
          end
        else
          format.html { redirect_to project_path(@project_attachment.project, tab_name: tab_name), notice: message }
        end
        format.js
      end
      # send mail
    else
      if @project_attachment.name == 'Data End Users'
        flash[:error] = 'Invalid file format please check format and re-upload'
        redirect_to project_path(@project, anchor: '!users')
      else
        redirect_to project_path(@project, anchor: '!uploads'),
                    alert: "Could not save file - #{@project_attachment.errors.full_messages}!"
      end
    end
  end

  # DELETE /project_memberships/1
  def destroy
    if @project_attachment.destroy
      redirect_to project_path(@project_attachment.project, anchor: '!uploads'), notice: 'Attachment removed'
    else
      error_message = 'Cannot remove Attachment'
      respond_to do |format|
        format.html { redirect_to project_path(@project_attachment.project, anchor: '!uploads'), alert: error_message }
        format.js { render js: "alert('#{error_message}')" }
      end
    end
  end

  def show
    send_data @project_attachment.attachment_contents, filename: @project_attachment.attachment_file_name, disposition: 'attachment'
  end

  private

  # Only allow a trusted parameter "white list" through.
  def project_attachment_params
    params.require(:project_attachment).permit(:name, :attachment, :file_to_download, :upload)
  end
end
