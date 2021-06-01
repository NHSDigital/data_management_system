# An abstract controller, from which all controllers can inherit.
class ApplicationController < ActionController::Base
  include ActionView::RecordIdentifier # for #dom_id
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :authenticate_user!
  include YubikeyAuthenticatable

  before_action :ensure_terms_accepted
  before_action :set_paper_trail_whodunnit # Allow acces to current_user
  before_action :establish_mailer_host_from_request

  helper NdrUi::BootstrapHelper
  helper NdrUi::TimeagoHelper
  helper NdrAuthenticate::ApplicationHelper

  def ensure_terms_accepted
    # Skip MBIS terms and conditions for show and tell.
    return
    return if Rails.env.development?
    return if accepted_terms_and_conditions?
    return unless enforce_terms_and_conditions?
    redirect_to(terms_and_conditions_url)
  end

  private

  def capture_exception(exception)
    NdrError.log(exception, NdrError.log_parameters.call(request), request)
  end

  helper_method def accepted_terms_and_conditions?
    session[:accepted_terms_and_conditions]
  end

  # Rescue CanCan exceptions
  rescue_from CanCan::AccessDenied do |exception|
    # TODO: use ndr_error to log authorisation failure?
    Rails.logger.warn(<<~MESSAGE)
      ***** ApplicationController: rescuing CanCan::AccessDenied *****

        current_user: #{current_user.try(:id)}

        message: #{exception.message}
        action:  #{exception.action}
        subject: #{exception.subject.inspect}

      ****************************************************************
    MESSAGE

    flash[:error] = exception.message.to_s
    request.referer.nil? ? root_url : request.referer
    redirect_to redirect_path
  end

  def redirect_path
    request.referer || root_url
    # redirect_to :back
  end

  # rescue_from(ActionController::RedirectBackError) { redirect_to root_url }

  # We don't want to affect devise.
  # TODO: Make this testable - difficulty stubbing
  #       session[:accepted_terms_and_conditions] in functional tests.
  def enforce_terms_and_conditions?
    !(Rails.env.test? || self.class.ancestors.include?(DeviseController))
  end

  # After signing out, go directly to the sign-in page
  # (rather than the root_url, which is the default)
  def after_sign_out_path_for(_resource)
    new_user_session_path
  end

  def establish_mailer_host_from_request
    ActionMailer::Base.default_url_options[:host]     ||= request.host_with_port
    ActionMailer::Base.default_url_options[:protocol] ||= request.protocol
  end
end
