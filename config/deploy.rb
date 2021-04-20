require 'bundler/capistrano'
require 'ndr_dev_support/capistrano/ndr_model'
require 'delayed/recipes'

set :application, 'mbis_front'
set :repository, 'https://github.com/PublicHealthEngland/data_management_system'
set :scm, :git

set :delayed_job_command, 'bin/delayed_job'
# set :delayed_job_args,    '-n 1'

# Use private repository for some configuration files
set :secondary_repo, 'https://ndr-svn.phe.gov.uk/svn/non-era/mbis'
# Private repository for encrypted credentials
# TODO: Add support for per-deployment encrypted credentials to ndr_dev_support
set :credentials_repo, 'https://ndr-svn.phe.gov.uk/svn/encrypted-credentials-store/mbis_front/base'

# Exclude these files from the deployment:
set :copy_exclude, %w(
  .ruby-version
  .git
  .svn
  ci-scripts
  config/deploy.rb
  doc
  private
  test
  vendor/cache/*-darwin-1?.gem
)

# Exclude gems from these bundler groups:
set :bundle_without, [:development, :test]

set :application, 'mbis_front'

# Paths that are symlinked for each release to the "shared" directory:
set :shared_paths, %w(
  config/database.yml
  config/excluded_mbisids.yml.enc
  config/keys
  config/puma.rb
  config/secrets.yml
  config/smtp_settings.yml
  config/master.key
  log
  private/mbis_data
  private/pseudonymised_data
  tmp
)

# paths in shared/ that the application can write to:
set :explicitly_writeable_shared_paths, %w( log tmp tmp/pids )

set :build_script, <<~SHELL
  set -e
  for fname in config/special_users.production.yml config/admin_users.yml config/odr_users.yml \
               config/user_yubikeys.yml; do
    rm -f "$fname"
    svn export --force "#{secondary_repo}/$fname" "$fname"
  done
  for fname in config/credentials.yml.enc; do
    rm -f "$fname"
    svn export --force "#{credentials_repo}/$fname" "$fname"
  done
SHELL

set :asset_script, <<~SHELL
  set -e
  cp config/database.yml.sample config/database.yml
  ruby -ryaml -e "puts YAML.dump('production' => { 'secret_key_base' => 'compile_me' })" > config/secrets.yml
  touch config/special_users.production.yml config/admin_users.yml config/odr_users.yml \
        config/user_yubikeys.yml
  RAILS_ENV=production bundle exec rake assets:precompile
  rm config/secrets.yml config/database.yml
SHELL

# ==========================================[ DEPLOY ]==========================================

namespace :deploy do
  desc 'Fix umask for code deployment'
  task :check_umask, except: { no_release: true } do
    umask = capture('umask').chomp
    unless umask == '0002'
      warn Rainbow('Warning: tweaking ~/.bashrc to set umask for deploying user')
      run('echo umask 002 >> ~/.bashrc # Fix invalid umask for deployment')
    end
  end
end

before 'deploy:update_code', 'deploy:check_umask'         # Deployment needs a permissive umask
before 'deploy:restart',     'deploy:check_umask'         # Deployment needs a permissive umask

after 'deploy:stop',    'delayed_job:stop'
after 'deploy:start',   'delayed_job:start'
after 'deploy:restart', 'delayed_job:restart'

before 'ndr_dev_support:update_out_of_bundle_gems' do
  set :out_of_bundle_gems, webapp_deployment ? %w[puma nio4r] : %w[]
end

namespace :ndr_dev_support do
  task :remove_svn_cache_if_needed do
    # no-op now we're using GitHub / branches
  end
end

namespace :bundle do
  desc 'Ensure bundler is properly configured'
  task :configure do
    # We need to use local configuration, because global configuration will be "global" for the
    # deploying user, rather than the application user.
    run <<~SHELL
      cd #{release_path} && bundle config --local build.pg --with-pg-config=/usr/pgsql-9.5/bin/pg_config
    SHELL
  end
end
before 'bundle:install', 'bundle:configure'

# ==========================================[ TARGETS ]==========================================

TARGETS = [
  [:live, :mbis_live,      'ncr-prescr-app1.phe.gov.uk', 22, 'mbis_live',      true],
  [:beta, :mbis_beta,      'ncr-prescr-app2.phe.gov.uk', 22, 'mbis_beta',      true],
  [:live, :mbis_god_live,  'ncr-prescr-app1.phe.gov.uk', 22, 'mbis_god_live',  false],
  [:beta, :mbis_brca_beta, 'ncr-prescr-app2.phe.gov.uk', 22, 'mbis_brca_beta', false]
]

TARGETS.each do |env, name, app, port, app_user, include_assets|
  add_target(env, name, app, port, app_user, include_assets)
end
