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
        else
          response_payload[:errors] = project.errors.full_messages
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
        attribute = attribute.dup.to_s.underscore
        attribute.prepend('article_') if attribute =~ /\A\d\w\z/

        value = value.dup.presence
        coerce_utf8!(value) if value.is_a?(String)

        yield(attribute, value)
      end
    end
  end
end
