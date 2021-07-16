module Projects
  # Supports the creating/updating of projects via PDF form submission.
  class ImportsController < ApplicationController
    include UTF8Encoding

    PERMITTED_CONTENT_TYPES = [
      'application/pdf'
    ].freeze

    load_and_authorize_resource :team
    load_and_authorize_resource :project

    # If we're importing a PDF as a new application, ensure we've spun up a new, correctly
    # configured project instance...
    before_action do
      @project ||= @team.projects.build(
        project_type:  ProjectType.find_by(name: 'Application'),
        assigned_user: current_user # should only be ODR application managers doing this
      )
    end

    before_action -> { authorize!(:import, @project) }
    before_action :validate_content_type

    # If the project is valid, it saves and redirects to the resource as in a conventional flow.
    # If the upload is invalid, save it anyway and redirect to the edit page for any issues to
    # be resolved (any errors/warnings will be marshaled so they can be displayed on the edit
    # page without having to re-run validation). It would be nice to do a conventional call to
    # e.g. `render 'projects/edit'` but:
    # a) The jQuery file upload library is expecting a JSON payload to be returned.
    # b) I've not found a way to wrangle Turbolinks (client-side) to do what is does under the
    #    hood to replace page content if I do send HTML back via that payload.
    # c) Not a blocker, but some massaging of `lookup_context.prefixes` needs to be done to
    #    even get `render` to not thow exceptions due to missing templates.
    #
    # ... so a bit of a redirect dance feels like the easiest approach at this time, even if
    # it's not the neatest of solutions.
    def create
      begin
        project = PdfApplicationFacade.new(@project)

        project.project_attachments.build(
          upload: uploaded_file,
          name:   ProjectAttachment::Names::APPLICATION_FORM
        )

        each_acroform_attribute do |attribute, value|
          project.try("#{attribute}=", value)
        end

        if project.save
          response_payload[:location] = project_path(project)
          flash[:notice] = t('projects.import.success')
        else
          marshal_errors_and_warnings_for(project)
          project.save(validate: false)
          response_payload[:location] = edit_project_path(project)
          flash[:warning] = t('projects.import.success_with_validity_warning')
        end
      rescue => e # rubocop:disable Style/RescueStandardError
        fingerprint,  = capture_exception(e)
        error_message = t('projects.import.ndr_error.message_html', fingerprint: fingerprint.id)

        response_payload[:errors] << error_message
      end

      render json: { files: [response_payload] }
    end

    private

    def uploaded_file
      params[:file]
    end

    def response_payload
      @response_payload ||= {
        name: uploaded_file.original_filename,
        size: uploaded_file.size,
        location: nil,
        errors: []
      }
    end

    def validate_content_type
      return if uploaded_file.content_type.in?(PERMITTED_CONTENT_TYPES)

      response_payload[:errors] << t(
        'projects.import.unpermitted_file_type',
        expected: PERMITTED_CONTENT_TYPES.join(', '),
        got: uploaded_file.content_type
      )

      render json: { files: [response_payload] }
    end

    def pdf_file
      @pdf_file ||= PDF::Reader.new(uploaded_file.tempfile)
    end

    def each_acroform_attribute
      pdf_file.acroform_data.each do |attribute, value|
        attribute = attribute.dup.to_s.underscore.tr(' ', '_')
        attribute.prepend('article_') if attribute =~ /\A\d\w\z/

        value = value.dup.presence
        coerce_utf8!(value) if value.is_a?(String)

        yield(attribute, value)
      end
    end

    # Store validation errors/warnings in the flash so they can be reapplied after redirection to
    # the edit page (saves having to run validation multiple times).
    def marshal_errors_and_warnings_for(project)
      flash[:validation] = {}

      %w[errors warnings].each do |type|
        issues = project.public_send(type)

        next if issues.none?

        dump = issues.marshal_dump
        dump.shift # we don't care about the base object

        flash[:validation][type] = dump
      end
    end
  end
end
