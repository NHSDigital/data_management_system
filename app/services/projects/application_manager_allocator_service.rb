module Projects
  # Allocates an ODR Application Manager to `project` based upon who has the fewest currently
  # assigned.
  class ApplicationManagerAllocatorService < ApplicationService
    class_attribute :allocation_threshold, default: 30

    attr_reader :project

    def initialize(project:)
      @project = project
    end

    def call
      return if project.project?
      return if project.assigned_user.present?

      if project.clone_of?
        previous_application_manager = Project.find_by(id: project.clone_of)&.assigned_user
        if previous_application_manager&.flagged_as_active?
          project.assigned_user = previous_application_manager
        end
      end

      project.assigned_user ||= next_available_application_manager

      (project.assigned_user_id_changed? && project.save).tap do |success|
        success ? notify_application_manager : notify_odr_managers
      end
    end

    private

    def available_application_managers
      User.application_managers.active.
        joins(<<~SQL).
          LEFT JOIN (
            #{Project.assigned.awaiting_sign_off.to_sql}
          ) projects ON projects.assigned_user_id = users.id
        SQL
        group(:id).
        having('COUNT(projects.id) < ?', allocation_threshold).
        order(Arel.sql('COUNT(projects.id) ASC'), last_name: :asc)
    end

    def next_available_application_manager
      available_application_managers.limit(1).first
    end

    def notify_application_manager
      return unless project.assigned_user

      ProjectsNotifier.project_assignment(project: project, assigned_to: project.assigned_user)
      ProjectsMailer.with(
        project: project,
        assigned_to: project.assigned_user,
        cc: User.odr_users.in_use.pluck(:email)
      ).project_assignment.deliver_later
    end

    def notify_odr_managers
      return if project.new_record?
      return if project.assigned_user

      ProjectsNotifier.project_awaiting_assignment(project: project)
      ProjectsMailer.with(project: project).project_awaiting_assignment.deliver_now
    end
  end
end
