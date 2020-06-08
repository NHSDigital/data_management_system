# Controller for Choice Nodes
class ChoicesController < NodesController
  load_and_authorize_resource :dataset_version
  load_and_authorize_resource class: 'Nodes::Choice', through: :dataset_version, shallow: true

  respond_to :js, :html

  def new
    @choice.parent_id = params[:parent_id]
    # @choice.child_nodes.build
  end

  def show
    @dataset_version = @choice.dataset_version
    @node = @choice
    super
  end

  def create
    @node = @choice
    @node.child_nodes =
      @dataset_version.nodes.where(name: choice_params[:existing_name].reject(&:blank?))
    super
  end

  def edit
    @dataset_version = @choice.dataset_version
  end

  def update
    @node = @choice
    super
  end

  def edit_error
    @dataset_version = @choice.dataset_version
  end

  def update_error
    @node = @choice
    super
  end

  def choice_params
    params.require(:nodes_choice).permit(
      :id, :parent_id, :type, :name, :dataset_version_id, :sort,
      :min_occurs, :max_occurs, :choice_type_id, :child_nodes, :existing_name => [],
      child_nodes_attributes: [:id, :_destroy],
      data_items_attributes: [:id, :type, :reference, :name, :description, :dataset_version_id,
                              :min_occurs, :max_occurs, :data_dictionary_element_name,
                              :governance_id, :sort, :_destroy],
      entities_attributes: [:id, :parent_id, :type, :name, :description, :dataset_version_id,
                            :min_occurs, :max_occurs, :sort],
      # child_nodes_attributes: [:child_node_ids, :_destroy]
    )
  end
end
