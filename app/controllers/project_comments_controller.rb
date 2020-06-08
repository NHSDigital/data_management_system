# This controller RESTfully manages Project Comments
class ProjectCommentsController < ApplicationController
  load_and_authorize_resource :project
  load_and_authorize_resource :project_comment, through: :project, shallow: true

  respond_to :js, :html

  def new; end

  # POST /project_attachments
  def create
    @project_comment.user = current_user
    @project_comment.user_role = 'odr' if current_user.odr?

    return_to_team_if_rejected

    if @project_comment.save
      respond_to do |format|
        format.html { redirect_to @project_comment.project, notice: 'Comment added' }
        format.js
      end
    else
      render :new
    end
  end

  private

  # special case where rejection comment triggers return to team
  def return_to_team_if_rejected
    return unless @project_comment.comment_type == 'DelegateRejection'
    @project.update(z_project_status: ZProjectStatus.find_by(name: 'New'))
    body = format(CONTENT_TEMPLATES['email_project_delegate_rejection']['body'],
                  project: @project.name, status: @project.current_state.id,
                  comment: @project_comment.comment)
    Notification.create!(title: "Delegate approver has rejected #{@project.name}",
                         body: body,
                         project_id: @project.id)
  end

  # Only allow a trusted parameter "white list" through.
  def project_comment_params
    params.require(:project_comment).permit(:comment, :comment_type, :project_node_id)
  end
end
