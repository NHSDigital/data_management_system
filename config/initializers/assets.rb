# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path
# Rails.application.config.assets.paths << Emoji.images_path

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
# Rails.application.config.assets.precompile += %w( search.js )

#  We've experienced segmentation faults when pre-compiling assets with libsass.
# Disabling Sprockets 4's export_concurrent setting seems to resolve the issues
# see: https://github.com/rails/sprockets/issues/633
Rails.application.config.assets.configure do |env|
  env.export_concurrent = false if env.respond_to?(:export_concurrent=)
end
