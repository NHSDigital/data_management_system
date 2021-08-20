# This controller RESTfully manages Project Dataset Level
class ProjectDatasetLevelsController < ApplicationController
  load_and_authorize_resource :project
  load_and_authorize_resource :project_dataset_level

  before_action :challenge_yubikey, only: :approve, if: :yubikey_protected_transition?

  respond_to :js, :html

  def approve
    @project_dataset_level.update(project_dataset_level_params)
  end

  def reject
    @project_dataset_level.update(project_dataset_level_params)
  end

  def reapply
    expiry_date = project_dataset_level_params['expiry_date'] ? project_dataset_level_params['expiry_date'] : 1.year.from_now

    new_pdl = ProjectDatasetLevel.new(project_dataset_id: @project_dataset_level.project_dataset_id,
                                      access_level_id: @project_dataset_level.access_level_id,
                                      expiry_date: expiry_date, selected: true, current: true)

    if new_pdl.save
      respond_to do |format|
        msg = 'Dataset Level Successfully Renewed'
        format.html { redirect_to project_path(new_pdl.project, anchor: '!datasets'), notice: msg }
        format.js { redirect_to project_path(new_pdl.project, anchor: '!datasets'), notice: msg }
      end
    else
      respond_to do |format|
        msg = 'Renewal failed - please provide a valid expiry date in the future'
        format.html { redirect_to project_path(new_pdl.project, anchor: '!datasets'), alert: msg }
        format.js { redirect_to project_path(new_pdl.project, anchor: '!datasets'), alert: msg }
      end
    end
  end

  def renew
    expiry_date = project_dataset_level_params['expiry_date'] ? project_dataset_level_params['expiry_date'] : 1.year.from_now

    new_pdl = ProjectDatasetLevel.new(project_dataset_id: @project_dataset_level.project_dataset_id,
                                      access_level_id: @project_dataset_level.access_level_id,
                                      expiry_date: expiry_date, selected: true, current: true)

    if new_pdl.save
      respond_to do |format|
        msg = 'Dataset Level Successfully Renewed'
        format.html { redirect_to project_path(new_pdl.project, anchor: '!datasets'), notice: msg }
        format.js { redirect_to project_path(new_pdl.project, anchor: '!datasets'), notice: msg }
      end
    else
      respond_to do |format|
        msg = 'Renewal failed - please provide a valid expiry date in the future'
        format.html { redirect_to project_path(new_pdl.project, anchor: '!datasets'), alert: msg }
        format.js { redirect_to project_path(new_pdl.project, anchor: '!datasets'), alert: msg }
      end
    end
  end

  private

  def project_dataset_level_params
    params.fetch(:project_dataset_level, {}).permit(:id, :approved, :decided_at, :expiry_date)
  end

  def yubikey_protected_transition?
    Rails.env.development? ? false : true
  end
end
