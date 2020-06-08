# Controller for Category Choice Nodes
class NodeCategoriesController < NodesController
  load_and_authorize_resource :dataset_version
  load_and_authorize_resource class: 'NodeCategory', through: :dataset_version, shallow: true

  before_action :authorize_user_for_editing

  respond_to :js, :html

  def new; end

  def show; end

  def node_category_matrix
    NodeCategoryMatrix.new(params).call
  end

  def update
    if perform_authorized_node_category_updates!(node_category_matrix)
      respond_to do |format|
        format.html { redirect_to @node.dataset_version, notice: message }
        format.js
        flash[:notice] = 'Node categories updated.'
      end
    else
      flash.now[:alert] = 'Cannot remove all node_categories!'
      redirect_to @node.dataset_version
    end
  end

  def authorize_user_for_editing
    @user ||= current_user
    authorize!(:edit_node_categories, @user)
  end

  def perform_authorized_node_category_updates!(clean_hash)
    number_of_node_categories = nil

    @node.transaction do
      clean_hash.each do |category_id, granted|
        node_category = @node.node_categories.find_or_initialize_by(category_id: category_id)
        authorize!(:toggle, node_category)

        if granted
          node_category.save! unless node_category.persisted?
        else
          node_category.destroy! if node_category.persisted?
        end
      end

      @node.reload
      number_of_node_categories = @node.categories.count
      raise ActiveRecord::Rollback if number_of_node_categories.zero?
    end

    number_of_node_categories.positive?
  end
end
