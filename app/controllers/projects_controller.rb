# This controller RESTfully manages proje &&cts
class ProjectsController < ApplicationController
  load_and_authorize_resource :team
  load_and_authorize_resource :project, through: :team, shallow: true,
                                        except: %i[dashboard cas_approvals], new: %i[import]

  before_action -> { authorize! :read, Project }, only: %i[dashboard cas_approvals]

  # include late to ensure correct callback order
  include Workflow::Controller
  include ProjectsHelper
  include UTF8Encoding

  respond_to :js, :html

  def index
    @projects = current_user.projects.active
    @projects = @projects.my_projects_search(search_params).order(updated_at: :desc)
    @projects = @projects.paginate(
      page: params[:assigned_projects_page],
      per_page: 10
    )
  end

  def dashboard
    # all tables apart from my_projects are currently scoped to only return mbis and odr
    @projects                     = Project.search(search_params).
                                    accessible_by(current_ability, :read).
                                    send(dashboard_projects_by_role(current_user)).
                                    by_project_type(type_filter).
                                    order(updated_at: :desc)
    @my_projects                  = current_user.projects.
                                    through_grant_of(ProjectRole.fetch(:owner)).
                                    my_projects_search(search_params).
                                    order(updated_at: :desc)
    @assigned_projects            = @projects.assigned_to(current_user, check_temporal: true)
    @unassigned_projects          = @projects.unassigned

    @projects = @projects.paginate(
      page: params[:projects_page],
      per_page: 10
    )

    @my_projects = @my_projects.paginate(
      page: params[:my_projects_page],
      per_page: 10
    )

    @assigned_projects = @assigned_projects.paginate(
      page: params[:assigned_projects_page],
      per_page: 10
    )

    @unassigned_projects = @unassigned_projects.paginate(
      page: params[:unassigned_projects_page],
      per_page: 10
    )
  end

  def show
    @readonly = true
    @team = @project.team
    @sub_resource_counts = {
      'communications': @project.communications.count,
      'comments': @project.comments.count,
      'project_nodes.comments': @project.project_nodes.joins(:comments).group(:id).count,
      'workflow/project_states.comments': @project.project_states.joins(:comments).group(:id).count
    }
  end

  # TODO: plugin multiple datasets
  def edit_data_source_items
    @data_source =
      # TODO: is this first condition redundant?
      if data_source_params[:data_source_id]
        @project.team.datasets.first.find(data_source_params[:data_source_id])
      else
        @project.datasets
      end
  end

  def cas_approvals
    @projects = Project.my_projects_search(search_params).accessible_by(current_ability, :read).
                order(updated_at: :desc)
    @my_dataset_approvals = @projects.cas_dataset_approval(current_user, [nil]).
                            order(updated_at: :desc)
    @my_access_approvals = @projects.cas_access_approval.order(updated_at: :desc)

    @my_dataset_approvals = @my_dataset_approvals.paginate(page: params[:page], per_page: 10)
    @my_access_approvals = @my_access_approvals.paginate(page: params[:page], per_page: 10)
  end

  def reset_project_approvals
    @project.reset_approvals
    redirect_to @project, notice: "#{@project.project_type_name} approval details reset"
  end

  def new
    @project.project_type ||= ProjectType.find_by(name: 'Project')
    @project.build_cas_application_fields if @project.project_type_name == 'CAS'
    @project.add_default_dataset
    @full_form = true
  end

  # POST /projects
  def create
    # TODO: can we do this elsewhere
    unless @project.project_type_name == 'CAS'
      @team = @project.team
      @project = @team.projects.build(project_params)
      @project.send(:add_current_user_as_contributor, current_user)
    end
    @project.initialize_workflow(current_user)

    if @project.save
      respond_to do |format|
        format.html { redirect_to @project, notice: "#{@project.project_type_name} was successfully created." }
        format.js { render action: 'show', id: @project.id }
      end
      @project.send(:clone_project_sub_details)
      # send mail
    else
      form_type = project_params['clone_of'].presence ? :duplicate : :new
      @full_form = project_params['clone_of'].presence ? false : true
      @duplicate = project_params['clone_of'].presence ? true : false
      respond_to do |format|
        format.html { render form_type }
        format.js { render form_type }
      end
    end
  end

  def edit
    @team = @project.team
    @full_form = true
  end

  # PATCH/PUT /projects/1
  def update
    @full_form = true

    # TODO: Really? Can't we just sack this off?
    if params[:flag_delete] == 'true'
      message = "#{@project.project_type_name} was successfully deleted."
      # @project.z_project_status_id = ZProjectStatus.find_by(name: 'Deleted')
      @project.transition_to(Workflow::State.find('DELETED'))
    else
      @team = @project.team
      message = "#{@project.project_type_name} was successfully updated."
    end

    if @project.update(project_params)
      flash[:notice] = message

      respond_to do |format|
        format.html do
          redirect_to project_path(@project, anchor: params['tab'])
        end
        format.js
      end
    else
      render :edit
    end
  end

  # DELETE /projects/1
  def destroy
    @team      = @project.team
    @destroyed = @project.transition_to(Workflow::State.find('DELETED'))

    respond_to do |format|
      format.js
      format.html do
        if @destroyed
          redirect_to @project.team, notice: "#{@project.project_type_name} was successfully destroyed."
        else
          redirect_to @project, notice: "#{@project.project_type_name} cannot be destroyed"
        end
      end
    end
  end

  def duplicate
    ignored_project_keys = %w[id name start_data_date end_data_date closure_reason_id]
    existing_project = Project.find(params[:id])
    existing_project_attrs = existing_project.attributes.except(*ignored_project_keys).dup
    existing_project_attrs['clone_of'] = params[:id]

    @project = Project.new(existing_project_attrs)
    @team = @project.team
    @full_form = false
    @duplicate = true
  end

  def assign
    previous_assignee = @project.assigned_user

    if @project.update(assign_params)
      alert  = @project.assigned_user ? :project_assignment : :project_awaiting_assignment
      kwargs = {
        project: @project,
        assigned_by: previous_assignee
      }

      kwargs[:assigned_to] = @project.assigned_user if alert == :project_assignment

      ProjectsNotifier.send(alert, **kwargs)
      ProjectsMailer.with(**kwargs).send(alert).deliver_now

      redirect_to @project, notice: "#{@project.project_type_name} was successfully assigned"
    else
      redirect_to @project, notice: "#{@project.project_type_name} could not be assigned!"
    end
  end

  # POST /team/:id/import
  # Endpoint to support (drag/drop) upload of PDF data applications.
  # TODO: Diet!
  def import
    upload  = params[:file]
    payload = { name: upload.original_filename, size: upload.size, location: nil, errors: [] }

    if upload.content_type.in? %w[application/pdf]
      begin
        reader  = PDF::Reader.new(upload.tempfile)
        project = PdfApplicationFacade.new(@project) do |resource|
          resource.project_type  = ProjectType.find_by(name: 'Application')
          resource.assigned_user = current_user # should only be ODR application managers doing this
          acroform_data          = reader.acroform_data.transform_values(&:presence)

          acroform_data.transform_keys(&:underscore).each do |attribute, value|
            attribute = "article_#{attribute}" if attribute =~ /\A\d\w\z/
            coerce_utf8!(value) if value.is_a?(String)
            resource.try("#{attribute}=", value)
          end

          resource.project_attachments.build(name: 'Application Form', upload: upload)
        end

        if project.save
          payload[:location] = project_path(@project)
        else
          payload[:errors] = project.errors.full_messages
        end
      rescue => e
        fingerprint, _log = capture_exception(e)
        payload[:errors] << t('projects.import.ndr_error.message_html', fingerprint: fingerprint.id)
      end
    else
      payload[:errors] << 'Unpermitted file type'
    end

    respond_to do |format|
      format.json do
        render json: { files: [payload] }
      end
    end
  end

  private

  def data_source_params
    params.permit(:data_source_id)
  end

  # Only allow a trusted parameter 'white list' through.
  def project_params
    params.require(:project).permit(:alternative_data_access_address,
                                    :alternative_data_access_postcode,
                                    :application_date,
                                    :data_access_address,
                                    :data_access_postcode, :description, :end_data_date,
                                    :how_data_will_be_used, :name,
                                    :senior_user_id, :start_data_date, :team_id,
                                    :z_project_status_id,
                                    :end_use_other, :data_to_contact_others,
                                    :data_to_contact_others_desc, :data_already_held_for_project,
                                    :data_linkage, :frequency, :frequency_other, :acg_support,
                                    :acg_who, :acg_date, :outputs, :outputs_other,
                                    :cohort_inclusion_exclusion_criteria,
                                    :informed_patient_consent, :level_of_identifiability,
                                    :s42_of_srsa, :approved_research_accreditation,
                                    :ethics_approval_obtained, :ethics_approval_nrec_name,
                                    :ethics_approval_nrec_ref, :legal_ethical_approved,
                                    :direct_care, :section_251_exempt, :cag_ref, :date_of_approval,
                                    :date_of_renewal, :regulation_health_services, :caldicott_email,
                                    :legal_ethical_approval_comments,
                                    :informed_patient_consent_mortality,
                                    :data_source_terms_accepted,
                                    :trackwise_id,
                                    :clone_of,
                                    :project_type_id,
                                    :project_purpose,
                                    :data_asset_required,
                                    :why_data_required, :public_benefit, :onwardly_share,
                                    :onwardly_share_detail, :data_already_held_detail,
                                    :programme_support_id, :programme_support_detail, :scrn_id,
                                    :programme_approval_date, :phe_contacts, :s251_exemption_id,
                                    :sponsor_name, :sponsor_add1, :sponsor_add2, :sponsor_city,
                                    :sponsor_postcode, :sponsor_country_id,
                                    :funder_name, :funder_add1, :funder_add2, :funder_city,
                                    :funder_postcode, :funder_country_id,
                                    :data_processor_name, :data_processor_add1,
                                    :data_processor_add2,
                                    :data_processor_city, :data_processor_postcode,
                                    :data_processor_country_id,
                                    :processing_territory_id,
                                    :processing_territory_other,
                                    :processing_territory_outsourced_id,
                                    :processing_territory_outsourced_other,
                                    :dpa_org_code, :dpa_org_name, :dpa_registration_end_date,
                                    :dpa_org_code_outsourced, :dpa_org_name_outsourced,
                                    :dpa_registration_end_date_outsourced,
                                    :security_assurance_id, :security_assurance_outsourced_id,
                                    :ig_code, :ig_code_outsourced, :ig_toolkit_version_outsourced,
                                    :additional_info, :awarding_body_ref,
                                    :owner_id, :main_contact_name, :main_contact_email,
                                    data_source_item_ids: [],
                                    membership_ids: [],
                                    output_ids: [],
                                    classification_ids: [],
                                    end_use_ids: [],
                                    lawful_basis_ids: [],
                                    dataset_ids: [],
                                    owner_grant_attributes: %i[id user_id project_id
                                                               roleable_id roleable_type],
                                    project_datasets_attributes:
                                      [:id, :project_id, :dataset_id,
                                       :terms_accepted, :_destroy,
                                       { project_dataset_levels_attributes:
                                       %i[id project_dataset_id selected
                                          access_level_id expiry_date ] }],
                                    project_attachments_attributes: %i[name attachment],
                                    # CAS
                                    cas_application_fields_attributes: cas_fields)
  end

  def cas_fields
    [
      :firstname, :surname, :jobtitle, :phe_email, :work_number, :organisation,
      :line_manager_name, :line_manager_email, :line_manager_number, :employee_type,
      :contract_startdate, :contract_enddate, :username, :address, :n3_ip_address,
      :reason_justification, :access_level, :extra_datasets_rationale,
      declaration: []
    ]
  end

  def approval_params
    params.require(:project).permit(:members_approved, :details_approved, :legal_ethical_approved)
  end

  def assign_params
    params.fetch(:project, {}).permit(:assigned_user_id)
  end

  def updating_data_source_items?
    params['project'].keys.include? 'data_source_item_ids'
  end

  def data_source_item_ids
    params['project']['data_source_item_ids'].reject(&:empty?).map(&:to_i)
  end

  def icd
    DataSourceItem.icd.map(&:id) & @data_source_item_ids
  end

  def geo
    DataSourceItem.geo.map(&:id) & @data_source_item_ids
  end

  def search_params
    params.fetch(:search, {}).permit(:name)
  end

  def type_filter
    return :all if search_params[:name].present?
    return :odr if current_user.odr? && params[:project_type].blank?
    return :all if params[:project_type].blank?

    params[:project_type].to_sym
  end
end
