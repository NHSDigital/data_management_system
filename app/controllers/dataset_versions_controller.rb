# This controller RESTfully manages Dataset Versions
class DatasetVersionsController < ApplicationController
  load_and_authorize_resource :dataset
  load_and_authorize_resource :dataset_version, through: :dataset, shallow: true

  respond_to :js, :html

  def new; end

  def show
    @readonly = true
    @fluid_layout = true
  end

  def create
    @dataset_version.send(:create_version_entity)
    if @dataset_version.save
      respond_to do |format|
        format.html { redirect_to datasets_path, notice: 'Version was successfully created.' }
        format.js
      end
    else
      render :new
    end
  end

  def update
    if @dataset_version.update(dataset_version_params)
      respond_to do |format|
        message = 'Dataset Version was successfully updated.'
        format.html { redirect_to datasets_path, notice: message }
        format.js { render :index }
      end
    else
      render :edit
    end
  end

  def download
    if @dataset_version.send(:nodes_valid_for_schema_build?)
      # TODO: publish should save the new version number and finalise version
      filename = @dataset_version.send(:zip_filename)
      temp_file = Tempfile.new(filename)

      begin
        SchemaPack.new(@dataset_version, nil, temp_file)
        zip_data = File.read(temp_file.path)
        send_data(zip_data, type: 'application/zip', disposition: 'attachment', filename: filename)
      ensure
        temp_file.close
        temp_file.unlink
      end
    else
      @dataset_version_invalid_nodes = @dataset_version.send(:invalid_nodes_for_schema_build)
      render :errors
    end
  end

  def publish
    if @dataset_version.send(:nodes_valid_for_schema_build?)
      @dataset_version.update_attribute(:published, true)
      redirect_to @dataset_version
    else
      @dataset_version_invalid_nodes = @dataset_version.send(:invalid_nodes_for_schema_build)
      render :errors
    end
  end

  def destroy
    @datasets = Dataset.all
    if @dataset_version.destroy
      respond_to do |format|
        msg = 'DatasetVersion was successfully destroyed.'
        format.html { redirect_to "/teams/#{@dataset_version.dataset.team.id}#!datasets",
                      notice: msg }
        format.js
      end
    else
      respond_to do |format|
        msg = 'Could not destroy version!'
        format.html { redirect_to "/teams/#{@dataset_version.dataset.team.id}#!datasets",
                      notice: msg }
        format.js { render js: "alert('#{msg}')" }
      end
    end
  end
  
  private

  # Only allow a trusted parameter "white list" through.
  def dataset_version_params
    params.require(:dataset_version).permit(:id, :semver_version, :dataset_id, :published)
  end
end
