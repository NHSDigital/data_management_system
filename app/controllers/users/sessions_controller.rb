module Users
  # Custom sessions controller, to allow up to override any devise default behaviour.
  class SessionsController < Devise::SessionsController
    before_action :check_failed_login_count, only: :new

    # If a Yubikey has been used, we ensure that it is its owner logging in with it:
    prepend_before_action :override_username_when_using_2fa, only: [:new, :create]

    # We can't double-check this until we have a user too:
    skip_before_action(:check_current_yubikey!, only: [:new, :create]) unless Rails.configuration.x.use_ndr_authenticate

    def new
      super
    end

    private

    def check_failed_login_count
      if failed_login?
        user = User.where(username: request.filtered_parameters['user']['username']).first
        return if user.nil?
        if user.failed_attempts == 2
          user.update(failed_attempts: 3)
          user.lock_access!
          flash[:alert] = CONTENT_TEMPLATES['user_account_authorization_fail']['body'] %
                          { full_name: user.full_name }
          user.wrong_password_notifiction
        end
        if user.failed_attempts == 1
          user.update(failed_attempts: 2)
          flash[:alert] = 'You have one more attempt before your account is locked.'
        end
        user.update(failed_attempts: 1) if user.failed_attempts.zero?
      end
    end

    def failed_login?
      (options = request.env['warden.options']) &&
        options[:action] == 'unauthenticated' && request.filtered_parameters['user']
    end

    # Override raw params hash directly, so both devise and warden are affected.
    # This enables us to continue using strong parameters.
    def override_username_when_using_2fa
      @yubikey_username = nil
      return unless perform_2fa?

      @yubikey_username = http_basic_username.presence
      #@yubikey_email = User.where(username: http_basic_username.presence).first.email
      if @yubikey_username.present?
        self.params = params.to_unsafe_h.tap do |raw_params|
          raw_params[:user] ||= {}
          raw_params[:user][:username] = @yubikey_username
        end
      end
    end

  end
end
