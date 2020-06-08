# This controller RESTfully manages Project Data Source Items
class ProjectNodesController < ApplicationController
  load_and_authorize_resource :project
  load_and_authorize_resource :project_node, through: :project, shallow: true

  respond_to :js, :html
  def new

  end

  # POST /project_memberships
  def create
    message = "#{@project_node.data_source_item.name} successfully added to " \
              "#{@project_node.project.name}."
    message += ' The project status has been set to New' if @project_node.project.submitted?
    if @project_node.save
      @project.project_comments.create(user_id: current_user.id,
                                       comment_type: 'DataSourceItemJustification',
                                       comment:  project_data_source_item_params[:comment],
                                       project_data_source_item_id: @project_node.id)

      respond_to do |format|
        format.html { redirect_to @project_node.project, notice: message }
        format.js
      end
      # send mail
    else
      render :new
    end
  end

  def update
    # TODO: audit who / when this was approved by
    @project_node.update(project_node_params)
  end

  def update_all
    # TODO: use update_all but errors were firing and no paper trail implemented
    @project_nodes.each do |item|
      item.update(project_node_params)
    end
  end

  # DELETE /project_memberships/1
  def destroy
    if @project_node.destroy
      ui_destroy
    else
      error_message = 'Cannot remove the item'
      respond_to do |format|
        format.html { redirect_to @project_node.project, alert: error_message }
        format.js { render js: "alert('#{error_message}')" }
      end
    end
  end

  private

  # Remove the row from the
  # list of project memberships
  def ui_destroy
    respond_to do |format|
      format.js do
        render js:  %(jQuery("##{dom_id(@project_node)}").hide('fast');
                     can_submit_to_odr(#{@project_node.project.unjustified_data_items});)
      end
    end
  end

  def project_node_params
    params.require(:project_node).permit(:id, :approved, :odr_comment,
                                         :project_node_id, :comment)
  end
end
