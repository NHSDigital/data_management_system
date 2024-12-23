TIME_PROCESS_STARTED = Time.now

require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

require 'ndr_error/middleware/public_exceptions'

module Mbis
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Dump the schema as SQL, rather than Rails migration DSL:
    config.active_record.schema_format = :sql

    # Configure the ActionDispatch::ShowExceptions middleware to use NdrError's exception logger:
    config.exceptions_app = NdrError::Middleware::PublicExceptions.new(Rails.public_path)

    config.autoloader = :zeitwerk
    config.eager_load_paths += %W[#{config.root}/lib]

    # Weird assets are not Ruby code:
    Rails.autoloaders.main.ignore("#{config.root}/lib/schema_browser/Template")

    config.action_mailer.delivery_method = :smtp
    smtp_fname = config.root.join('config/smtp_settings.yml')
    if File.exist?(smtp_fname)
      smtp_config = ERB.new(File.read(smtp_fname)).result
      config.action_mailer.smtp_settings =
        YAML.safe_load(smtp_config, permitted_classes: [Symbol], aliases: true)[Rails.env]
      if ENV['SMTP_USERNAME'].present?
        config.action_mailer.smtp_settings[:user_name] = ENV['SMTP_USERNAME']
      end
      if ENV['SMTP_PASSWORD'].present?
        config.action_mailer.smtp_settings[:password] = ENV['SMTP_PASSWORD']
      end
    elsif !Rails.env.test?
      warn 'Warning: Missing config/smtp_settings.yml -- some services may not work.'
    end

    config.active_job.queue_adapter = :delayed_job

    config.action_view.form_with_generates_ids = true

    config.i18n.default_locale    = :en
    config.i18n.fallbacks         = true
    config.i18n.available_locales = %i[en en-odr]

    # TODO: Would be nice to push this out to a YAML file and access via `config_for`
    # so that we can avoid hardcoding...
    config.x.user.internal_domains = ['phe.gov.uk', 'ukhsa.gov.uk']

    # TODO: Old Rails 6.0 default; disable this
    ActiveSupport.utc_to_local_returns_utc_offset_times = false

    # TODO: Old Rails 6.1 default; disable this
    # Fails rails test test/models/concerns/workflow/model_test.rb:180
    config.active_support.executor_around_test_case = false

    # TODO: Old Rails 6.1 default; disable this
    # Fixtures are incomplete, e.g. test/fixtures/memberships.yml needs to be defined
    config.active_record.verify_foreign_keys_for_fixtures = false

    # Old Rails 6.1 default, required by devise_saml_authenticatable version 1.9.1
    # cf. https://github.com/apokalipto/devise_saml_authenticatable/issues/237
    # If we don't have this, the redirect when logging out from ADFS throws an application error.
    Rails.application.config.action_controller.raise_on_open_redirects = false
  end
end
