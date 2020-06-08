# Controller for Category Choice Nodes
class CategoryChoicesController < NodesController
  load_and_authorize_resource :dataset_version
  load_and_authorize_resource class: 'Nodes::CategoryChoice',
                              through: :dataset_version, shallow: true

  respond_to :js, :html

  def new
    @category_choice.parent_id = params[:parent_id]
  end

  def show
    @dataset_version = @category_choice.dataset_version
    @node = @category_choice
    super
  end

  def create
    @node = @category_choice
    super
  end

  def edit
    @dataset_version = @category_choice.dataset_version
  end

  def update
    @node = @category_choice
    super
  end

  def category_choice_params
    params.require(:nodes_category_choice).permit(
      :id, :parent_id, :type, :name, :dataset_version_id, :min_occurs, :max_occurs, :sort
    )
  end
end
