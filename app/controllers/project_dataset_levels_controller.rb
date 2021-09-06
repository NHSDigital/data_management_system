# This controller RESTfully manages Project Dataset Level
class ProjectDatasetLevelsController < ApplicationController
  load_and_authorize_resource :project
  load_and_authorize_resource :project_dataset_level

  before_action :challenge_yubikey, only: :approve, if: :yubikey_protected_transition?
  before_action :close_existing_approved_levels, only: :approve

  respond_to :js, :html

  def approve
    @project_dataset_level.update(status_id: 'approved', decided_at: Time.zone.now)
  end

  def reject
    @project_dataset_level.update(status_id: 'rejected', decided_at: Time.zone.now)
  end

  def reapply
    new_pdl = ProjectDatasetLevel.new(project_dataset_id: @project_dataset_level.project_dataset_id,
                                      access_level_id: @project_dataset_level.access_level_id,
                                      expiry_date: expiry_date, selected: true)

    respond_response('Reapplication', new_pdl)
  end

  def renew
    new_pdl = ProjectDatasetLevel.new(project_dataset_id: @project_dataset_level.project_dataset_id,
                                      access_level_id: @project_dataset_level.access_level_id,
                                      expiry_date: expiry_date, selected: true)

    respond_response('Renewal', new_pdl)
  end

  private

  def project_dataset_level_params
    params.fetch(:project_dataset_level, {}).permit(:id, :expiry_date)
  end

  def yubikey_protected_transition?
    Rails.env.development? ? false : true
  end

  def expiry_date
    if project_dataset_level_params['expiry_date']
      project_dataset_level_params['expiry_date']
    else 1.year.from_now
    end
  end

  def respond_response(type, new_pdl)
    if new_pdl.save
      respond_to do |format|
        msg = "#{type} request created succesfully"
        format.html { redirect_to project_path(new_pdl.project, anchor: '!datasets'), notice: msg }
        format.js { redirect_to project_path(new_pdl.project, anchor: '!datasets'), notice: msg }
      end
      @project_dataset_level.update(status_id: 2) if type == 'Renewal'
    else
      respond_to do |format|
        msg = "#{type} failed - please provide a valid expiry date in the future"
        format.html { redirect_to project_path(new_pdl.project, anchor: '!datasets'), alert: msg }
        format.js { redirect_to project_path(new_pdl.project, anchor: '!datasets'), alert: msg }
      end
    end
  end

  def close_existing_approved_levels
    ProjectDatasetLevel.same_access_level_levels(@project_dataset_level).where(status_id: [2, 4]).
      update_all(status_id: 5)
  end
end
