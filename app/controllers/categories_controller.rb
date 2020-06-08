# Controller for Category Choice Nodes
class CategoriesController < NodesController
  load_and_authorize_resource :dataset_version
  load_and_authorize_resource class: 'Category', through: :dataset_version, shallow: true

  respond_to :js, :html

  def new; end

  def show; end

  def create
    if @category.save
      @categories = @category.dataset_version.categories
      respond_to do |format|
        msg = 'Category was successfully created.'
        format.html { redirect_to dataset_version_categories_path, notice: msg }
        format.js
      end
    else
      render :new
    end
  end

  def edit
    @dataset_version = @category.dataset_version
  end

  def update
    if @category.update(category_params)
      @categories = @category.dataset_version.categories
      @dataset_version = @category.dataset_version
      respond_to do |format|
        msg = 'Category successfully updated.'
        format.html { redirect_to dataset_version_categories_path(@dataset_version), notice: msg }
        format.js
      end
    else
      render :edit
    end
  end

  def destroy
    @categories = @category.dataset_version.categories
    @dataset_version = @category.dataset_version
    if @category.destroy
      respond_to do |format|
        msg = 'Category was successfully destroyed.'
        format.html { redirect_to dataset_version_categories_path(@dataset_version), notice: msg}
        format.js
      end
    else
      respond_to do |format|
        msg = 'Could not destroy category!'
        format.html { redirect_to dataset_version_categories_path(@dataset_version), notice: msg }
        format.js { render js: "alert('#{msg}')" }
      end
    end
  end

  def category_params
    params.require(:category).permit(
      :id, :name, :dataset_version_id, :sort
    )
  end
end
