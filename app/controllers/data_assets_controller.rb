# This controller manages a subset of Datasets known as ODR data assets so that ODR can carry on
# their workflow
class DataAssetsController < ApplicationController
  load_and_authorize_resource :team
  load_and_authorize_resource :dataset, through: :team, shallow: true

  respond_to :js, :html

  def index
    @datasets ||= Dataset.odr
    @datasets = @datasets.odr.search(search_params).
                paginate(page: params[:page], per_page: 25).order(:name)
  end

  def show
    # TODO: remove use of last
    @dataset_version = @dataset.dataset_versions.last
    @readonly = true
  end

  private

  def search_params
    params.fetch(:search, {}).permit(:name)
  end
end
