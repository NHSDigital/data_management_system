# RESTfully manages `Release`s.
class ReleasesController < ApplicationController
  load_and_authorize_resource :project
  load_and_authorize_resource through: :project, shallow: true, through_association: :global_releases

  def index
    @releases = @releases.paginate(page: params[:page], per_page: 25)
  end

  def show; end

  def new; end

  def edit; end

  def create
    if @release.save
      redirect_to project_path(@project, anchor: '!releases'), notice: 'Release created successfully'
    else
      render :new
    end
  end

  def update
    if @release.update(resource_params)
      redirect_to project_path(@release.project, anchor: '!releases'), notice: 'Release updated successfully'
    else
      render :edit
    end
  end

  def destroy
    @release.destroy

    redirect_to project_path(@release.project, anchor: '!releases'), notice: 'Release destroyed successfully'
  end

  private

  def resource_params
    params.require(:release).permit(
      %i[
        referent_gid
        invoice_requested_date
        invoice_sent_date
        phe_invoice_number
        po_number
        ndg_opt_out_processed_date
        cprd_reference
        actual_cost
        vat_reg
        income_received
        drr_no
        cost_recovery_applied
        individual_to_release
        release_date
      ]
    )
  end
end
