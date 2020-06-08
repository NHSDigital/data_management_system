# Adds support for yubikey 2FA, using http_basic auth.
# Actual OTPW verification is done by an mod_authn_yubikey,
# in apache on an auth server. Those credentials are still
# passed through to the application as HTTP headers, which
# enables the yubikey to be tested against an application
# user.
#
# Some of this logic could be added to a custom warden strategy,
# but by modifying the controller we can (for example) pre-fill
# the username field if a yubikey is used.
module YubikeyAuthenticatable
  extend ActiveSupport::Concern

  # Expect yubikeys to be used in production. In the test environment,
  # we enable the codepath, but are more lenient (see #should_check_current_yubikey?)
  # - we can test yubikey behaviour using integration tests if we
  # choose, but are not forced use them in functional tests.
  PERFORM_2FA = Rails.env.test? || Rails.env.production?

  included do
    # In case the auth server's yubikey listing becomes stale,
    # we should check the yubikey status on each request (so
    # keys can be revoked immediately, for example).
    before_action :check_current_yubikey!

    helper_method :current_yubikey
  end

  private

  # If a user has got through the auth server with a yubikey

  # fail any login attempts.
  def check_current_yubikey!
    return unless should_check_current_yubikey?

    if http_basic_username != current_user.username
      sign_out(current_user)
      throw(:warden, message: :second_factor_failure)
    end
  end

  # If there is a signed-in user, in what circumstances should
  # we verify they have submitted an appropriate yubikey too?
  def should_check_current_yubikey?
    return if Rails.configuration.x.use_ndr_authenticate
    # We use an integration test to verify yubikey behaviour;
    # in functional tests, we don't submit the header every time.
    return if Rails.env.test? && request.authorization.nil?

    # If 2FA auth is enabled, and we have a user with whom
    # we can try and check the association of a yubikey with:
    perform_2fa? && user_signed_in?
  end

  # Returns the yubikey in use, or nil.
  def current_yubikey
    public_id = http_basic_otpw.to_s[0, 12]
    return unless public_id.present?
    VALID_YUBIKEYS[public_id]
  end

  def perform_2fa?
    PERFORM_2FA
  end

  def http_basic_username
    username = nil
    authenticate_with_http_basic do |user, _p|
      username = user
      true
    end
    username
  end

  def http_basic_otpw
    otpw = nil
    authenticate_with_http_basic do |_u, password|
      otpw = password
      true
    end
    otpw
  end

  def find_by_id(public_id)
    return 'd'
  end
end
