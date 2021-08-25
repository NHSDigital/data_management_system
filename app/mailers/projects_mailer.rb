# Sends emails regarding Project related activity
class ProjectsMailer < ApplicationMailer
  include Workflow::Mail

  before_action :load_project

  def project_assignment
    @assigned_to = params[:assigned_to]
    @assigned_by = params[:assigned_by]
    @comments    = params[:comments]

    return if @assigned_to.blank?

    return unless @project.odr? || @project.project?
    return unless @assigned_to == @project.assigned_user ||
                  @assigned_to == @project.temporally_assigned_user

    mail(
      to: @assigned_to.email,
      cc: params[:cc],
      subject: 'Project Assignment'
    )
  end

  def project_awaiting_assignment
    return unless @project.odr? || @project.project?

    recipients   = User.odr_users.pluck(:email)
    @assigned_by = params[:assigned_by]

    mail(to: recipients, subject: 'Project Awaiting Assignment') if recipients.any?
  end

  private

  def load_project
    @project ||= params[:project]
  end
end
