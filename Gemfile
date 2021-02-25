source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 6.0.3.5'
# Use postgresql as the database for Active Record
gem 'pg'
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
gem 'mini_racer'

# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks', '~> 5.x'

gem 'webpacker', '~> 4.x'

gem 'devise', '~> 4.7', '>=  4.7.1'
gem 'cancancan', '~> 3.0'
gem 'highline'
gem 'cocoon'
gem 'paper_trail', '~> 10.0'
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

gem 'ndr_support', '~> 5.7.1'
gem 'ndr_import'
gem 'ndr_error', '~> 2.0'
gem 'ndr_workflow', '1.1.6'
gem 'ndr_ui'
gem 'activemodel-caution', tag: 'rails_6_0_3_5', git: 'https://github.com/PublicHealthEngland/activemodel-caution.git'
gem 'ndr_pseudonymise', '~> 0.2.6'
gem 'ndr_authenticate', '0.2.3.1'

gem 'axlsx'
gem 'bootstrap-table-rails'
gem 'zip-zip' # annoying backwards compatibility for old axlsx version

gem 'regexp-examples'
gem 'loofah', '>= 2.3.1' # address CVE-2019-15587
gem 'nokogiri', '~> 1.11'

gem 'jquery-rails'
gem 'jquery-ui-rails'

group :development, :test do
  gem 'pry-rails'
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'
  gem 'ndr_dev_support', '~> 6.0'
  # gem 'ndr_dev_support', branch: 'flakey_tests', git: 'https://github.com/PublicHealthEngland/ndr_dev_support.git'

  gem 'minitest'

  gem 'simplecov'
  gem 'mocha'
  gem 'capybara-email'
  gem 'capistrano', '~> 2.15.7'
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
  gem 'web-console', '~> 3.0'

  # Spring speeds up development by keeping your application running in the background.
  # Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'railroady'
end
