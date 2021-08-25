# RESTfully manages `Contract`s
class ContractsController < ApplicationController
  load_and_authorize_resource :project
  load_and_authorize_resource through: :project, shallow: true, through_association: :global_contracts

  # We'll handle this one manually...
  skip_authorize_resource only: %i[download]

  def index
    @contracts = @contracts.paginate(page: params[:page], per_page: 25)
  end

  def show; end

  def new; end

  def edit; end

  def create
    if @contract.save
      redirect_to project_path(@project, anchor: '!contracts'), notice: 'Contract created successfully'
    else
      render :new
    end
  end

  def update
    if @contract.update(resource_params)
      redirect_to project_path(@contract.project, anchor: '!contracts'), notice: 'Contract updated successfully'
    else
      render :edit
    end
  end

  def destroy
    @contract.destroy

    redirect_to project_path(@contract.project, anchor: '!contracts'), notice: 'Contract destroyed successfully'
  end

  def download
    authorize!(:read, @contract)

    if @contract.attachment
      send_data @contract.attachment_contents, type: @contract.attachment_content_type,
                                               filename: @contract.attachment_file_name,
                                               disposition: 'attachment'
    else
      redirect_to @contract, notice: 'No contract document attached'
    end
  end

  private

  def resource_params
    params.require(:contract).permit(
      %i[
        referent_gid
        contract_version
        contract_sent_date
        contract_received_date
        contract_executed_date
        contract_start_date
        contract_end_date
        advisory_letter_date
        destruction_form_received_date
        upload
      ]
    )
  end
end
