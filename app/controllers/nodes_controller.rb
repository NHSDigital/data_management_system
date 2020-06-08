# This controller RESTfully manages Nodes
class NodesController < ApplicationController
  load_and_authorize_resource :dataset_version
  load_and_authorize_resource :node, through: :dataset_version, shallow: true

  respond_to :js, :html

  def show
    respond_to do |format|
      format.html { render :show }
      format.js { render :show }
    end
  end

  def new; end

  def create
    respond_to do |format|
      if @node.save
        message = 'Data Item was successfully created.'
        format.html { redirect_to @node.dataset_version, notice: message }
        format.js
      else
        format.js { render :new }
      end
    end
  end

  def edit
    respond_to do |format|
      format.js { render :edit }
    end
  end

  def update
    @dataset_version ||= @node.dataset_version
    respond_to do |format|
      if @node.update(node_params)
        message = 'Dataset Version was successfully updated.'
        format.html { redirect_to dataset_version_path(@dataset_version), notice: message }
        format.js
      else
        format.js { render :edit }
      end
    end
  end

  def update_error
    @dataset_version ||= @node.dataset_version
    respond_to do |format|
      if @node.update(node_params)
        message = 'Node was successfully updated.'
        format.html { redirect_to dataset_version_path(@dataset_version), notice: message }
        format.js { render 'nodes/update_error' }
      else
        format.js { render :edit_error }
      end
    end
  end

  def destroy
    if @node.destroy
      ui_destroy
    else
      projects = @node.projects.active.map(&:name).to_sentence
      error_message = "#{@node.name} is currently being " \
                      "used in the following projects: #{projects}"
      respond_to do |format|
        format.html { redirect_to@node.dataset_version, alert: error_message }
        format.js { render js: "alert('#{error_message}')" }
      end
    end
  end

  def sort
    params['child_nodes'].reject(&:blank?).each.with_index(1) do |node, sort|
      Node.where(id: node.split('_').last).update_all(sort: sort)
    end

    head :ok
  end

  private

  # Remove the row from the
  # list of data source items
  def ui_destroy
    respond_to do |format|
      format.js
    end
  end

  # Only allow a trusted parameter "white list" through.
  def node_params
    send(@node.type.split('::').last.underscore + '_params')
  end
end
