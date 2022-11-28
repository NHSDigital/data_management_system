source 'https://rubygems.org'

gem 'activemodel-caution', '6.1.7' # must match rails version
gem 'rails', '~> 6.1.7'

# Use postgresql as the database for Active Record
# gem 'pg', '>= 0.18', '< 2.0'
gem 'pg', '~> 1.2.3' # Support old CentOS 7 PostgreSQL client 9.2.24
# use Puma as the app server
gem 'puma', '~> 4.0', '>= 4.3.5' # Bump to >= 4.3.5 in response to CVE-2020-11076 & CVE-2020-11077
# Use SCSS for stylesheets
gem 'sass-rails'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby
# gem 'mini_racer'
# Allow mini_racer version to be overridden in a custom Gemfile
# We need this for mini_racer on Mac OS Monterey, where the old libv8 no longer compiles
unless defined?(BUNDLER_OVERRIDE_MINI_RACER) && BUNDLER_OVERRIDE_MINI_RACER
  # We have built our own CentOS 7 binaries for mini_racer
  # (with separate gem files for Ruby 2.7 and Ruby 3.0)
  # Copy these into place if needed
  gem_fname = 'mini_racer-0.6.2-x86_64-linux.gem'
  gem_dir = if RUBY_PLATFORM == 'x86_64-linux' && File.exist?('/etc/os-release') &&
               File.readlines('/etc/os-release').grep(/^(ID="centos"|VERSION_ID="7")$/).count == 2
              "vendor/mini_racer-x86_64-linux-ruby#{RUBY_VERSION.split('.')[0..1].join}"
            end
  require 'fileutils'
  if gem_dir && Dir.exist?(gem_dir)
    begin
      FileUtils.cp "#{gem_dir}/#{gem_fname}", 'vendor/cache/'
    rescue Errno::EACCES
      # Deployer account may not have write access to vendor/cache/
      # (in which case the file in vendor/cache/ is probably already correct)
    end
  else
    FileUtils.rm_f "vendor/cache/#{gem_fname}"
  end
  gem 'libv8-node', '~> 16.10'
  # gem 'mini_racer', '~> 0.6.2'
  gem 'mini_racer', '0.6.2'
end

# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks', '~> 5.x'

gem 'webpacker'

gem 'daemons'
gem 'delayed_job', '~> 4.1'
gem 'delayed_job_active_record'

gem 'devise', '~> 4.7', '>=  4.7.1'
gem 'cancancan', '~> 3.0'
gem 'highline'
gem 'cocoon'
gem 'paper_trail', '~> 12.0'
gem 'paper_trail-association_tracking'
gem 'will_paginate'
gem 'possibly'
gem 'pry'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

gem 'ndr_authenticate', '~> 0.3'
gem 'ndr_error', '~> 2.0'
gem 'ndr_import'
gem 'ndr_pseudonymise', '~> 0.4.1'
gem 'ndr_support', '~> 5.9'
gem 'ndr_ui'
gem 'ndr_workflow', '~> 1.2', '>= 1.2.2'

gem 'axlsx'
gem 'bootstrap-table-rails'
gem 'zip-zip' # annoying backwards compatibility for old axlsx version

gem 'regexp-examples'
gem 'loofah', '>= 2.3.1' # address CVE-2019-15587
gem 'nokogiri', '~> 1.11'

gem 'jquery-rails'
gem 'jquery-ui-rails'

group :test do
  gem 'simplecov'

  gem 'minitest'

  gem 'mocha'
  gem "capistrano", ">= 2.5.0", "< 3.0", :require => false # Capistrano 3.0 has some potentially incompatible changes. Leave version unchanged until move to Rails 3 complete
  gem 'capybara-email'
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
  gem 'guard-rubocop'
  gem 'guard-shell'
  gem 'guard-test'
  gem 'guard-livereload', '~> 2.5', require: false
  # Conditionally requiring ensures that the Gemfile.lock remains consistent cross-platform.
  mac_osx = (RUBY_PLATFORM =~ /darwin/)
  gem 'terminal-notifier-guard', require: (mac_osx ? 'terminal-notifier-guard' : false)

  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console'

  gem 'rack-mini-profiler'

  # Spring speeds up development by keeping your application running in the background.
  # Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'railroady'
end
