# Generates `Notification`s relating to `Project`s.
class ProjectsNotifier
  class << self
    def project_assignment(project:, assigned_to:, assigned_by: nil)
      create_notification(
        user_id: assigned_to.id,
        title: 'Project Assignment',
        body: "#{project.name} (#{project.project_type.name}) has been assigned to you by " \
              "#{assigned_by&.full_name || 'the MBIS system'}.\n\n"
      )
    end

    def project_awaiting_assignment(project:, assigned_by: nil)
      return unless project.odr? || project.project?

      create_notification(
        odr_users: true,
        title: 'Project Awaiting Assignment',
        body: "#{project.name} (#{project.project_type.name}) requires allocation to an " \
              "application manager #{"(was #{assigned_by.full_name})" if assigned_by}.\n\n"
      )
    end

    private

    def create_notification(**attributes)
      Notification.create(attributes) do |notification|
        notification.generate_mail = false
        yield(notification) if block_given?
      end
    end
  end
end
