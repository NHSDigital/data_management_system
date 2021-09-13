# RESTfully manages DPIAs
class DataPrivacyImpactAssessmentsController < ApplicationController
  load_and_authorize_resource :project
  load_and_authorize_resource :dpia, through: :project, shallow: true, parent: false,
                                     through_association: :global_dpias,
                                     class: 'DataPrivacyImpactAssessment'

  # We'll handle this one manually...
  skip_authorize_resource :dpia, only: %i[download]

  def index
    @dpias = @dpias.paginate(page: params[:page], per_page: 25)
  end

  def show; end

  def new; end

  def edit; end

  def create
    if @dpia.save
      redirect_to project_path(@project, anchor: '!dpias'), notice: 'DPIA created successfully'
    else
      render :new
    end
  end

  def update
    if @dpia.update(resource_params)
      redirect_to project_path(@dpia.project, anchor: '!dpias'), notice: 'DPIA updated successfully'
    else
      render :edit
    end
  end

  def destroy
    @dpia.destroy

    redirect_to project_path(@dpia.project, anchor: '!dpias'), notice: 'DPIA destroyed successfully'
  end

  def download
    authorize!(:read, @dpia)

    if @dpia.attachment
      send_data @dpia.attachment_contents, type: @dpia.attachment_content_type,
                                           filename: @dpia.attachment_file_name,
                                           disposition: 'attachment'
    else
      redirect_to @dpia, notice: 'No DPIA document attached'
    end
  end

  private

  def resource_params
    params.require(:data_privacy_impact_assessment).permit(
      %i[
        referent_gid
        ig_toolkit_version
        ig_score
        ig_assessment_status_id
        review_meeting_date
        dpia_decision_date
        upload
      ]
    )
  end
end
