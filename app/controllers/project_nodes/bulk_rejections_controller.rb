module ProjectNodes
  # Endpoints for handling business logic of bulk rejecting `ProjectNode`s
  class BulkRejectionsController < ::ApprovalsController
    load_and_authorize_resource :project
    before_action -> { authorize!(:approve, ProjectNode) }

    def create
      @project.transaction do
        @project.project_nodes.find_each do |project_node|
          project_node.approved = false
          project_node.assign_attributes(comment_params)
          project_node.save!
        end
      end

      respond_to do |format|
        format.js { render 'project_nodes/bulk_approvals/create' }
        format.any { redirect_to project_path(@project, anchor: '!data') }
      end
    end

    def destroy
      @project.transaction do
        @project.project_nodes.find_each do |project_node|
          project_node.update!(approved: nil)
        end
      end

      respond_to do |format|
        format.js { render action: :create }
        format.any { redirect_to project_path(@project, anchor: '!data') }
      end
    end

    private

    def resource_params
      params.fetch(:project, {})
    end

    def comments_count
      @comments_count ||= @project.project_nodes.joins(:comments).group(:id).count
    end
    helper_method :comments_count
  end
end
