module ProjectNodes
  # Endpoints for handling business logic of rejecting a `ProjectNode`
  class RejectionsController < ::ApprovalsController
    load_and_authorize_resource :project_node
    before_action -> { authorize!(:approve, @project_node) }

    def create
      @project_node.approved = false
      @project_node.assign_attributes(comment_params)
      @project_node.save

      respond_to do |format|
        format.js { render 'project_nodes/approvals/create' }
        format.any { redirect_to project_path(@project_node.project, anchor: '!data') }
      end
    end

    def destroy
      @project_node.update(approved: nil)

      respond_to do |format|
        format.js { render action: :create }
        format.any { redirect_to project_path(@project_node.project, anchor: '!data') }
      end
    end

    private

    def resource_params
      params.fetch(:project_node, {})
    end
  end
end
