module Projects
  module Members
    # Endpoints for handling business logic of approving the members section of a `project`
    class ApprovalsController < ::ApprovalsController
      load_and_authorize_resource :project
      before_action -> { authorize!(:approve_members, @project) }

      def create
        @project.members_approved = true
        @project.assign_attributes(comment_params)
        @project.save

        redirect_to project_path(@project, anchor: '!users')
      end

      def destroy
        @project.update(members_approved: nil)

        redirect_to project_path(@project, anchor: '!users')
      end

      private

      def resource_params
        params.fetch(:project, {})
      end
    end
  end
end
