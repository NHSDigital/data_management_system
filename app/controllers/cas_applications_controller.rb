class CasApplicationsController < ApplicationController
  before_action :find_cas_application, only: [:edit, :update, :show]

  def index
  end

  def new
    @cas_application = CasApplication.new
  end

  def edit
  end

  def create
    @cas_application = CasApplication.new
    @cas_application.assign_attributes(cas_application_params)
    if @cas_application.save
      redirect_to cas_application_path(@cas_application), notice: 'Success'
    else
      render :new
    end
  end

  def update
    @cas_application.assign_attributes(cas_application_params)
    if @cas_application.save
      redirect_to cas_application_path(@cas_application), notice: 'Success'
    else
      render :edit
    end
  end

  def show
  end


private

  def find_cas_application
    @cas_application = CasApplication.find(params[:id])
  end

  def cas_application_params
    params.require(:cas_application).permit(
      :firstname, :surname, :jobtitle, :phe_email, :work_number, :organisation,
      :line_manager_name, :line_manager_email, :line_manager_number, :employee_type,
      :contract_startdate, :contract_enddate, :username, :address, :n3_ip_address,
      :reason_justification, :access_level, :extra_datasets_rationale,
      extra_datasets: [], declaration: []
    )
  end
end
