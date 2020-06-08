# Sends emails regarding Project related activity
class ProjectsMailer < ApplicationMailer
  before_action :load_project

  def project_assignment
    return unless @project.assigned_user

    @assigned_by = params[:assigned_by]

    mail(
      to: @project.assigned_user.email,
      cc: User.odr_users.pluck(:email),
      subject: 'Project Assignment'
    )
  end

  def project_awaiting_assignment
    recipients   = User.odr_users.pluck(:email)
    @assigned_by = params[:assigned_by]

    mail(to: recipients, subject: 'Project Awaiting Assignment') if recipients.any?
  end

  private

  def load_project
    @project ||= params[:project]
  end
end
