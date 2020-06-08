# Controller for Entity Nodes
class EntitiesController < NodesController
  load_and_authorize_resource :dataset_version
  load_and_authorize_resource class: 'Nodes::Entity', through: :dataset_version, shallow: true

  respond_to :js, :html

  def new
    @entity.parent_id = params[:parent_id]
  end

  def show
    @dataset_version = @entity.dataset_version
    @node = @entity
    super
  end

  def create
    @node = @entity
    super
  end

  def edit
    @dataset_version = @entity.dataset_version
  end

  def update
    @node = @entity
    super
  end

  def edit_error
    @dataset_version = @entity.dataset_version
  end

  def update_error
    @node = @entity
    super
  end

  def entity_params
    params.require(:nodes_entity).permit(
      :id, :parent_id, :type, :name, :description, :dataset_version_id, :min_occurs, :max_occurs,
      :sort
    )
  end
end
