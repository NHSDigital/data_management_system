# --- This block is taken from era/config/initializers/filesystems_paths.rb
# --- It ensures that the correct path is used for the YAML configuration file
# --- that SafePath uses. The SafePath class itself is defined in the
# --- ndr_support gem.

# SafePath stores the contents of the appropriate filesystem_paths.yml
# file in at the class level. Running Rails in development mode
# was causing this configuration to periodically be lost between requests.
#
# Configuration#to_prepare allows us to reset things lost
# between development environment application reloads.
Rails.application.config.to_prepare do
  missing_safepath_config =
    if Rails.env.development? || Rails.env.test?
      # Allow overwrites for code-reloading development and (spring) test environments;
      # The ActionDispatch::Reloader for Middleware triggers initializers to re-run.
      begin
        SafePath.fs_paths.blank?
      rescue SecurityError
        Rails.logger.info("[SafePath] Warning: reconfiguring SafePath in #{Rails.env}!")
        true
      end
    else
      # This block should only run once outside of development, so
      # we'll definitely want to configure SafePath.
      true
    end

  if missing_safepath_config
    # We attempt to use an environment-specific config file;
    # as we don't have SafePath available yet, we need to sanitize
    # the place we're going to look:
    rails_env = Rails.env
    raise(SecurityError, 'Invalid Rails.env!') unless rails_env =~ /\A[a-z_]+\Z/

    # Default back to config/filesystem_paths.yml if there
    # is no environment-specific config available:
    path = Rails.root.join('config', 'environments', rails_env, 'filesystem_paths.yml')
    path = Rails.root.join('config', 'filesystem_paths.yml') unless File.exist?(path)

    # Setup or die:
    SafePath.configure!(path)
  end
end
