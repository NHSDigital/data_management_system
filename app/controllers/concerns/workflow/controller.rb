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

      after_action :allocate_project, only: :transition
    end

    # PATCH
    # Initiates a change to a project's state.
    # `ProjectsController` should already be loading/authorizing the `Project` resource.
    def transition
      @project.transition_to(@state, current_user) do |project, project_state|
        authorize!(:create, project_state)
        project.assign_attributes(transition_params)
      end

      if @project.current_state.id.in? %w[DPIA_REJECTED DPIA_MODERATION]
        ProjectsNotifier.project_dpia_updated(project: @project,
                                              status: @project.current_state.id,
                                              id_of_user_to_notify: @project.assigned_user_id)
      end

      redirect_to @project
    end

    private

    def transition_params
      params.fetch(:project, {}).permit(:closure_reason_id, :assigned_user_id,
                                        comments_attributes: %i[user_id body])
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
  end
end
