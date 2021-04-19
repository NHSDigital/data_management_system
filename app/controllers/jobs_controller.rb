class JobsController < ApplicationController
  load_and_authorize_resource class: 'Delayed::Job'

  rescue_from ActiveRecord::RecordNotFound do
    redirect_to jobs_path, alert: 'Job not found'
  end

  def index
    @jobs = @jobs.order(:id).paginate(page: params[:page], per_page: 25)
  end

  def show; end

  def destroy
    if @job.failed? && @job.destroy
      redirect_to jobs_path, notice: 'Job was successfully destroyed'
    else
      redirect_to jobs_path, alert: 'Cannot destroy job'
    end
  end
end
