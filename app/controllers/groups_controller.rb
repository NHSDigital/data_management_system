# Controller for Group Nodes
class GroupsController < NodesController
  load_and_authorize_resource :dataset_version
  load_and_authorize_resource class: 'Nodes::Group', through: :dataset_version, shallow: true

  respond_to :js, :html

  def new
    @group.parent_id = params[:parent_id]
  end

  def show
    @dataset_version = @group.dataset_version
    @node = @group
    super
  end

  def create
    @node = @group
    super
  end

  def edit
    @dataset_version = @group.dataset_version
  end

  def update
    @node = @group
    super
  end

  def group_params
    params.require(:nodes_group).permit(
      :id, :parent_id, :type, :name, :dataset_version_id, :sort
    )
  end
end
