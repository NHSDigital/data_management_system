# This controller RESTfully manages Datasets
class DatasetsController < ApplicationController
  load_and_authorize_resource :team
  load_and_authorize_resource :dataset, through: :team, shallow: true

  respond_to :js, :html

  def index
    @datasets = @datasets.search(search_params).paginate(page: params[:page], per_page: 25).
                for_browsing.order(:name)
  end

  def new; end

  def create
    if @dataset.save
      respond_to do |format|
        format.html { redirect_to datasets_path, notice: 'Dataset successfully created.' }
        format.js
      end
    else
      render :new
    end
  end

  def show
    # TODO: remove use of last
    @dataset_version = @dataset.dataset_versions.last
    @readonly = true
  end

  def update
    if @dataset.update(dataset_params)
      respond_to do |format|
        format.html { redirect_to datasets_path, notice: 'Dataset was successfully updated.' }
        format.js { render :index }
      end
    else
      render :edit
    end
  end

  def destroy
    @datasets = Dataset.all
    if @dataset.destroy
      respond_to do |format|
        msg = 'Dataset was successfully destroyed.'
        format.html { redirect_to "/teams/#{@dataset.team.id}#!datasets", notice: msg }
        format.js
      end
    else
      respond_to do |format|
        msg = 'Could not destroy version!'
        format.html { redirect_to "/teams/#{@dataset.team.id}#!datasets", notice: msg }
        format.js { render js: "alert('#{msg}')" }
      end
    end
  end

  private

  # Only allow a trusted parameter "white list" through.
  def dataset_params
    params.require(:dataset).permit(:name, :full_name, :terms, :dataset_type_id, :team_id)
  end

  def search_params
    params.fetch(:search, {}).permit(:name)
  end
end
