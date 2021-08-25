module Workflow
  # Contains mailer logic for generating emails about changes to a `project`s `state`.
  module Mail
    extend ActiveSupport::Concern

    included do
      before_action :load_user
      before_action :load_current_user
      before_action :load_comments
    end

    # Acts as a wrapper around other transition related emails, automagically determining the
    # correct mail to send based on a project's type and state, for convenience.
    # NOTE: The generic `:transition` email/option is currently excluded because without a
    # mechanism for users to manage what kind of status updates they're interested in, this could
    # have the potential to be a bit spammy (especially considering pre-existing behaviour of
    # mailing all users associated with the project).
    def state_changed
      state_key        = @project.current_state.to_lookup_key
      project_type_key = @project.project_type.to_lookup_key

      methods = [
        :"#{project_type_key}_transitioned_to_#{state_key}",
        :"transitioned_to_#{state_key}",
        :"#{project_type_key}_transitioned"
        # :transitioned
      ]

      method = methods.find { |method_name| respond_to?(method_name) }

      public_send(method) if method
    end

    # A default/generic message to send when any project type changes to any state.
    def transitioned
      # For translation lookup purposes. Capture the current method name (handling aliases
      # appropriately) and set a variable for use as a translation lookup prefix; the intent is
      # that it allows better reuse of the default template, whilst still having dynamic
      # translation content.
      @i18n_prefix = __callee__

      @interpolations = default_interpolations

      transition_email do |format|
        render_default_template(format)
      end
    end
    alias transitioned_to_rejected transitioned
    alias application_transitioned_to_contract_completed transitioned
    alias application_transitioned_to_contract_rejected  transitioned

    def application_transitioned_to_rejected
      @interpolations = default_interpolations.merge!(
        closure_reason: @project.closure_reason.value
      )

      transition_email do |format|
        render_default_template(format)
      end
    end
    alias eoi_transitioned_to_rejected application_transitioned_to_rejected

    private

    def load_user
      @user = params[:user]
    end

    def load_current_user
      @current_user = params[:current_user]
    end

    def load_comments
      @comments = params[:comments]
    end

    def default_interpolations
      {
        current_user: @current_user.full_name,
        type:         @project.project_type_name,
        state:        @project.current_state_name,
        title:        @project.name
      }
    end

    def render_default_template(format)
      format.html { render :transitioned }
      format.text { render :transitioned }
    end

    def transition_email(**options, &block)
      # For translation lookup purposes. If not already set, infer from the calling method.
      @i18n_prefix ||= caller_locations.first.label

      subject = t(
        :subject,
        scope:   [:projects_mailer],
        default: [:'transitioned.subject', action_name.humanize],
        type:    @project.project_type_name
      )

      localize_mail(params[:locale]) do
        mail(options.merge(to: @user.email, subject: subject), &block)
      end
    end

    # Leveraging locales as a means to present varying content to different audiences, for the
    # (debatably) same email. Inspired by:
    # https://guides.rubyonrails.org/action_view_overview.html#localized-views
    # https://guides.rubyonrails.org/i18n.html#localized-views
    def localize_mail(locale = I18n.default_locale, &block)
      I18n.with_locale(locale, &block)
    end
  end
end
