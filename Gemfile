source 'https://rubygems.org'

# The activemodel-cautions gem is ours, so not available rubygems.org.
# The .gem file is in vendor/cache - if this is lost, or the gem needs
# updating, the source (along with development instructions in the
# README) is available at:
#  https://github.com/NHSDigital/activemodel-caution.git

gem 'activemodel-caution', '7.0.8' # Supports rails ~> 7.0.8.0
gem 'rails', '~> 7.0.4', '>= 7.0.8.1'

# Use old psych for YAML on Ruby 3.1 until we move to Rails 7.0.4
# so that we can continue to use aliases in config/locales/en.yml
# cf. https://stackoverflow.com/questions/71191685/visit-psych-nodes-alias-unknown-alias-default-psychbadalias
gem 'psych', '4.0.4' # Exactly match the version on Ruby 3.1
gem 'stringio', '3.0.1.2' # psych dependency: exactly match the version on Ruby 3.1

# Use postgresql as the database for Active Record
gem 'pg', '~> 1.4.6' # All client instance have postgres version >= 9.3

# use Puma as the app server
gem 'puma', '~> 6.0'
gem 'puma-daemon', require: false

# Use SCSS for stylesheets
gem 'sass-rails'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby
# gem 'mini_racer'
gem 'mini_racer', '~> 0.14'

gem 'parser'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks', '~> 5.x'

gem 'webpacker'

gem 'daemons'
gem 'delayed_job', '~> 4.1'
gem 'delayed_job_active_record'

gem 'cancancan', '~> 3.0'
gem 'cocoon'
gem 'devise', '~> 4.7', '>=  4.7.1'
gem 'highline'
gem 'paper_trail', '~> 12.0'
gem 'paper_trail-association_tracking'
gem 'possibly'
gem 'pry'
gem 'will_paginate'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# net-imap (via ndr_error) requires date. Puma needs us to stick to the ruby default version.
gem 'date', '3.1.3' # Lock to Ruby 3.0 version of gem for live service

# TODO: 2023-09-03: Updating mail to 2.8.1 causes tests failures on Rails 6.1
gem 'mail', '>= 2.1.1', '< 2.8.0' # mail 2.8.0 and 2.8.0.1 have major hidden bugs

gem 'ndr_authenticate', '~> 0.3', '>= 0.3.3'
gem 'ndr_error', '~> 2.0'
gem 'ndr_import'
gem 'ndr_pseudonymise', '~> 0.4.1'
gem 'ndr_support', '~> 5.9'
gem 'ndr_ui', '~> 3.3'
gem 'ndr_workflow', '~> 1.2', '>= 1.2.2'

gem 'bootstrap-table-rails', '~> 1.20.2'
gem 'caxlsx', '~> 4'

gem 'loofah', '>= 2.3.1' # address CVE-2019-15587
gem 'nokogiri', '~> 1.11'
gem 'regexp-examples'

gem 'jquery-rails'
gem 'jquery-ui-rails', '>= 7.0.0'
gem 'rainbow'

group :test do
  gem 'simplecov'

  gem 'minitest'

  # Capistrano 3.0 has some potentially incompatible changes.
  # Leave version unchanged workarounds can be found
  gem 'capistrano', '>= 2.5.0', '< 3.0', require: false
  gem 'capybara-email'
  gem 'mocha'
end

group :development, :test do
  gem 'pry-rails'
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'
  gem 'ndr_dev_support', '~> 7.0'
  # gem 'ndr_dev_support', branch: 'flakey_tests', git: 'https://github.com/PublicHealthEngland/ndr_dev_support.git'
end

group :development do
  gem 'guard'
  gem 'guard-livereload', '~> 2.5', require: false
  gem 'guard-rubocop'
  gem 'guard-shell'
  gem 'guard-test'
  # Conditionally requiring ensures that the Gemfile.lock remains consistent cross-platform.
  mac_osx = (RUBY_PLATFORM =~ /darwin/)
  gem 'terminal-notifier-guard', require: (mac_osx ? 'terminal-notifier-guard' : false)

  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console'

  gem 'rack-mini-profiler'

  gem 'railroady'
  # Spring speeds up development by keeping your application running in the background.
  # Read more: https://github.com/rails/spring
  gem 'spring'
end
