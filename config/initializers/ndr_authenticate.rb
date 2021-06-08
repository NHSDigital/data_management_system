# =============================================================================

# Feature toggle to support initial testing of NdrAuthenticate in the wild.
enabled = ENV.key?('NDR_AUTH')
Rails.configuration.x.use_ndr_authenticate = enabled
Rails.logger.warn 'NdrAuthenticate is ENABLED!' if enabled

# =============================================================================

NdrAuthenticate.configure do |config|
  # Name of the user class within the host application.
  config.user_class = 'User'

  # Callable object that controls availability of SSO logins.
  config.sso_enabled = lambda do |request|
    hosts = [
      'betambisapp.unix.phe.gov.uk',
      'prescriptions.phe.nhs.uk',
      'betadatamanagementsystem.phe.gov.uk',
      'datamanagementsystem.phe.gov.uk'
    ]

    request.host.in?(hosts)
  end

  config.load_defaults(:phe)

  if ENV.key?('RAILS_MASTER_KEY') || File.exist?(Rails.root.join('config', 'master.key'))
    config.devise.saml_config.private_key = Rails.application.credentials.saml[:private_key]

    config.yubikey_api_id  = Rails.application.credentials.yubikey[:api_id]
    config.yubikey_api_key = Rails.application.credentials.yubikey[:api_key]
  end

  config.invalid_otp_reasons = {
    missing:       ->(otp, _user, _) { otp.blank? },
    user_mismatch: ->(otp, user, _)  { user.yubikey != otp.slice(0, 12) },
    invalid:       ->(otp, _user, _) { !NdrAuthenticate::Yubikey::Verify.call(otp) }
  }
end

# FIXME: Temporary hacks to support toggled NdrAuthenticate support
Devise.setup do |config|
  if enabled
    config.authentication_keys = [:email] # For database authentication only

    # Fallback to email lookup in order to support existing users logging in via SAML
    # for the first time (who wouldn't be found by the federated ID).
    # NOTE: This is not foolproof and we can/should expect some issues. It looks like the User
    # model has been configured to treat email addresses as case insensitive for login purposes
    # but not in terms of uniqueness, so theoretically there's potential for multiple accounts with
    # (ostensibly) the same email...
    config.saml_resource_locator = lambda do |model, saml_response, auth_value|
      user = model.find_by(Devise.saml_default_user_key => auth_value)

      return user if user

      key   = 'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress'
      email = saml_response.attributes.value_by_saml_attribute_key(key)
      users = model.where('email ILIKE ?', email).all
      users.one? ? users.first : nil
    end

    # Configure SAML certificates for ADFS; these will need to be provided and may need periodic
    # rotation in live environments (the files can be replaced as needed).
    certificates_path = Rails.root.join('config/certificates/saml')
    encryption_path   = certificates_path.join('encryption.phe.adfs.pem')
    signing_path      = certificates_path.join('signing.phe.adfs.pem')
    encryption_certs  = File.read(encryption_path).split(/\n{2,}/) if File.exist?(encryption_path)
    signing_certs     = File.read(signing_path).split(/\n{2,}/)    if File.exist?(signing_path)

    config.saml_config.idp_cert_multi = {
      encryption: Array.wrap(encryption_certs),
      signing:    Array.wrap(signing_certs)
    }
  else
    config.saml_route_helper_prefix = 'saml'
    config.parent_controller        = 'ApplicationController'
    config.router_name              = nil
  end
end
