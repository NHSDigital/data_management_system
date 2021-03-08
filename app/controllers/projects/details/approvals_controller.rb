module Projects
  module Details
    # Endpoints for handling business logic of approving the details section of a `project`
    class ApprovalsController < ::ApprovalsController
      load_and_authorize_resource :project
      before_action -> { authorize!(:approve_details, @project) }

      def create
        @project.details_approved = true
        @project.assign_attributes(comment_params)
        @project.save

        redirect_to @project
      end

      def destroy
        @project.update(details_approved: nil)

        redirect_to @project
      end

      private

      def resource_params
        params.fetch(:project, {})
      end
    end
  end
end
