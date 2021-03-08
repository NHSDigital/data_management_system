# Generates `Notification`s relating to `Project`s.
class ProjectsNotifier
  class << self
    def project_assignment(project:, assigned_by: nil)
      create_notification(
        user_id: project.assigned_user_id,
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

    def project_dpia_updated(project:, status:, id_of_user_to_notify:, comment: nil)
      return unless status.in? %w[DPIA_REJECTED DPIA_MODERATION]
      return unless id_of_user_to_notify

      user_to_notify = User.find(id_of_user_to_notify)

      if status == 'DPIA_REJECTED'
        return unless user_to_notify&.application_manager?

        title = "#{project.name} - DPIA Rejected"
        template = 'email_application_manager_dpia_rejected'
      elsif status == 'DPIA_MODERATION'
        return unless user_to_notify&.senior_application_manager?

        title = "#{project.name} - DPIA Moderation Required"
        template = 'email_senior_manager_dpia_moderation'
      end

      send_dpia_email(project: project,
                      title: title,
                      body_template: template,
                      user_to_notify: user_to_notify,
                      comment: comment)
    end

    private

    def create_notification(**attributes)
      Notification.create(attributes) do |notification|
        notification.generate_mail = false
        yield(notification) if block_given?
      end
    end

    def send_dpia_email(project:, title:, body_template:, user_to_notify:, comment:)
      NotificationMailer.send_message(
        create_notification(
          title: title,
          body: CONTENT_TEMPLATES[body_template]['body'] %
          { project: project.name,
            comments: comment },
          project_id: project.id
        ),
        user_to_notify
      ).deliver_now
    end
  end
end
