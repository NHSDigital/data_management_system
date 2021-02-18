module Projects
  module Legal
    # Endpoints for handling business logic of approving the legal/ethical section of a `project`
    class ApprovalsController < ::ApprovalsController
      load_and_authorize_resource :project
      before_action -> { authorize!(:approve_legal, @project) }

      def create
        @project.legal_ethical_approved = true
        @project.assign_attributes(comment_params)
        @project.save

        redirect_to project_path(@project, anchor: '!legal')
      end

      def destroy
        @project.update(legal_ethical_approved: nil)

        redirect_to project_path(@project, anchor: '!legal')
      end

      private

      def resource_params
        params.fetch(:project, {})
      end
    end
  end
end
