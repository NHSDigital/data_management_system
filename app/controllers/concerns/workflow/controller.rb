module Workflow
  # Contains workflow related behaviour for the `ProjectsController` controller.
  module Controller
    extend ActiveSupport::Concern

    included do
      load_resource :state, only: :transition, class: 'Workflow::State', id_param: :state

      # We can't use the :yubikey_protected macro because NdrAuthenticate doesn't currently
      # allow for conditional challenges, nor are any serialized params restored until later
      # in the process. We'll work around that for now...
      before_action :restore_params,    only: :transition, prepend: true
      before_action :challenge_yubikey, only: :transition, if: :yubikey_protected_transition?

      with_options only: :transition do
        after_action :allocate_project
        around_action :notify_temporally_assigned_user
        after_action  :send_transition_email
      end
    end

    # PATCH
    # Initiates a change to a project's state.
    # `ProjectsController` should already be loading/authorizing the `Project` resource.
    def transition
      @project.transition_to(@state, current_user) do |project, project_state|
        authorize!(:create, project_state)
        project.assign_attributes(transition_params)

        if temporally_assigned_user
          project_state.assign_to!(
            user: temporally_assigned_user,
            assigning_user: current_user
          )
        end

        # NOTE: Meh. Rather than adding and drilling through layers of nested attributes we'll
        # redirect the comment attributes onto the `project_state` object instead.
        project_state.assign_attributes(comment_params)
      end

      redirect_to @project
    end

    private

    def transition_params
      params.fetch(:project, {}).permit(:closure_reason_id)
    end

    def comment_params
      return {} unless params.dig(:project, :comments_attributes, '0')

      params.fetch(:project).permit(comments_attributes: %i[body]).tap do |object|
        object[:comments_attributes]['0'][:user] = current_user
      end
    end

    def temporally_assigned_user
      return unless id ||= params.dig(:project, :project_state, :assigned_user_id)

      @temporally_assigned_user ||=
        @state.assignable_users.where.not(id: current_user).find_by(id: id)
    end

    def send_transition_email
      return unless @project.current_state == @state

      notifiable_users.find_each do |user|
        kwargs = { project: @project, user: user, current_user: current_user }

        # TODO: Is there a more elegant way of handling this? Like determining the correct locale
        # from a project role?
        if user == @project.assigned_user
          kwargs[:comments] = extract_comment_from_params
          kwargs[:locale]   = :'en-odr'
        elsif user == @project.temporally_assigned_user
          kwargs[:comments] = extract_comment_from_params
        end

        # NOTE: Returns NullMail if `state_changed` returns via guard clause, so no need for
        # safe navigation operator...
        ProjectsMailer.with(**kwargs).state_changed.deliver_later
      end
    end

    # Who should receive emails about changes to a `project`s workflow position.
    # In lieu of a subscription based model where users can manage their own desired status updates.
    # NOTE: yuk.
    def notifiable_users
      # Does the user performing the transition need notifying?
      scope = @project.users.internal.where.not(id: current_user)

      # Copied from original project rejected notification...
      scope = scope.where.not(id: @project.users.odr_users) if @project.application?

      scope
    end

    def notify_temporally_assigned_user
      initial_project_state = @project.current_project_state
      yield
      new_project_state = @project.current_project_state

      return if initial_project_state == new_project_state
      return if new_project_state.assigned_user_id.blank?

      ProjectsMailer.with(
        project:     @project,
        assigned_to: temporally_assigned_user,
        assigned_by: current_user,
        comments:    extract_comment_from_params
      ).project_assignment.deliver_later
    end

    def allocate_project
      return unless @project.current_state.id == 'SUBMITTED'

      Projects::ApplicationManagerAllocatorService.call(project: @project)
    end

    def yubikey_protected_transition?
      return false if Rails.env.development?

      @project.current_state.
        transitions.
        applicable_to(@project.project_type).
        find_by(next_state: @state)&.
        requires_yubikey?
    end

    def extract_comment_from_params
      comment_params.dig(:comments_attributes, '0', :body)
    end
  end
end
