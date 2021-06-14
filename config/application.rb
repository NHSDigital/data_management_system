require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

require 'ndr_error/middleware/public_exceptions'

module Mbis
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

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
    smtp_fname = config.root.join('config', 'smtp_settings.yml')
    if File.exist?(smtp_fname)
      config.action_mailer.smtp_settings =
        YAML.load_file(smtp_fname)[Rails.env]
    elsif !Rails.env.test?
      $stderr.puts 'Warning: Missing config/smtp_settings.yml -- some services may not work.'
    end

    config.active_job.queue_adapter = :delayed_job

    config.action_view.form_with_generates_ids = true
  end
end
