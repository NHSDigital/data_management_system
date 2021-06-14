# Preview all emails at http://localhost:3000/rails/mailers/projects_mailer
class ProjectsMailerPreview < ActionMailer::Preview
  def project_assignment
    project = Project.first
    project.assigned_user = User.application_managers.first

    ProjectsMailer.with(
      project:     project,
      assigned_to: project.assigned_user,
      assigned_by: project.assigned_user,
      comments:    'This is a test!'
    ).project_assignment
  end

  def project_awaiting_assignment
    project = Project.first

    ProjectsMailer.with(project: project).project_awaiting_assignment
  end
end
