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

  def transitioned
    project =
      Project.joins(:project_type, :current_state).
      merge(ProjectType.application).
      merge(Workflow::State.where(id: 'SUBMITTED')).
      order(:id).
      limit(1).
      first

    ProjectsMailer.with(
      project:      project,
      user:         project.owner,
      current_user: project.owner
    ).transitioned
  end

  def transitioned_to_rejected
    project =
      Project.joins(:project_type, :current_state).
      merge(ProjectType.application).
      merge(Workflow::State.where(id: 'REJECTED')).
      order(:id).
      limit(1).
      first

    ProjectsMailer.with(
      project:      project,
      user:         project.owner,
      current_user: project.assigned_user,
      comments:     'RAWR!'
    ).state_changed
  end
end
