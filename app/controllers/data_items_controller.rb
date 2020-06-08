# Controller for Data Item Nodes
class DataItemsController < NodesController
  load_and_authorize_resource :dataset_version
  load_and_authorize_resource class: 'Nodes::DataItem', through: :dataset_version, shallow: true

  respond_to :js, :html

  def new
    @dataset_version = @data_item.dataset_version
    @data_item.parent_id = params[:parent_id]
  end

  def show
    @dataset_version = @data_item.dataset_version
    @node = @data_item
    super
  end

  def create
    @node = @data_item
    super
  end

  def edit
    @dataset_version = @data_item.dataset_version
  end

  def update
    @node = @data_item
    @node.data_dictionary_element_name = data_item_params[:data_dictionary_element_name]
    super
  end

  def edit_error
    @dataset_version = @data_item.dataset_version
  end

  def update_error
    @node = @data_item
    super
  end

  def data_item_params
    params.require(:nodes_data_item).permit(
      :id, :parent_id, :type, :name, :description, :dataset_version_id, :min_occurs, :max_occurs,
      :governance_id, :sort, :reference, :data_dictionary_element_name
    )
  end
end
