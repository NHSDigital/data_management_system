# RESTfully manages amendments.
class ProjectAmendmentsController < ApplicationController
  load_and_authorize_resource :project
  load_and_authorize_resource through: :project, shallow: true

  def index
    @project_amendments = @project_amendments.paginate(page: params[:page], per_page: 25)
  end

  def show
    respond_to do |format|
      format.html
      format.pdf do
        send_data @project_amendment.attachment_contents,
                  type:        @project_amendment.attachment_content_type,
                  filename:    @project_amendment.attachment_file_name,
                  disposition: 'inline'
      end
    end
  end

  def new; end

  def edit; end

  def create
    if @project_amendment.save
      redirect_to after_manipulation_path, notice: 'Amendment created successfully'
    else
      render :new
    end
  end

  def update
    if @project_amendment.update(resource_params)
      redirect_to after_manipulation_path, notice: 'Amendment updated successfully'
    else
      render :edit
    end
  end

  def destroy
    @project_amendment.destroy

    notice = 'Amendment destroyed successfully' if @project_amendment.destroyed?
    notice ||= 'Could not destroy Amendment!'

    redirect_to after_manipulation_path, notice: notice
  end

  private

  def resource_params
    params.require(:project_amendment).permit(:requested_at, { labels: [] }, :upload)
  end

  def after_manipulation_path
    project = @project || @project_amendment.project
    project_path(project, anchor: '!amendments')
  end
end
