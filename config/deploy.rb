# Avoid spurious deprecation warning on STDERR with capistrano 2 and bundler 2.x
set :bundle_cmd, 'BUNDLE_SILENCE_DEPRECATIONS=true bundle'

require 'bundler/capistrano'
require 'ndr_dev_support/capistrano/ndr_model'
require 'delayed/recipes'
require 'resolv'

set :application, 'mbis_front'
# AWS circular deployments can override the repository by setting environment variable
# NDR_DEPLOY_REPOSITORY, e.g. 'file:///home/mbis_app/data_management_system/.git'
# This allows local deployment from a git working copy snapshot.
set :repository, ENV.fetch('CAP_DEPLOY_REPOSITORY',
                           'https://github.com/NHSDigital/data_management_system.git')
set :scm, :git
ssh_options[:compression] = 'none' # Avoid pointless zlib warning

set :delayed_job_command, 'bin/delayed_job'
# set :delayed_job_args,    '-n 1'

if Resolv.getaddresses('ndr-svn.phe.gov.uk').any?
  # Use private repository for some configuration files
  set :secondary_repo, 'https://ndr-svn.phe.gov.uk/svn/non-era/mbis'
  # Private repository for encrypted credentials
  # TODO: Add support for per-deployment encrypted credentials to ndr_dev_support
  set :credentials_repo,
      'https://ndr-svn.phe.gov.uk/svn/encrypted-credentials-store/mbis_front/base'
else
  # For off-premise deployments, configuration will be provided to the startup script
  # in Base64-encoded environment variables.
  set :secondary_repo, nil
  set :credentials_repo, nil
end

# Exclude these files from the deployment:
set :copy_exclude, %w[
  .ruby-version
  .git
  .svn
  ci-scripts
  config/deploy.rb
  doc
  private
  test
  vendor/cache/*-arm64-darwin.gem
  vendor/cache/*-darwin-1?.gem
  vendor/cache/*-darwin1?.gem
  vendor/cache/*-darwin-2?.gem
  vendor/cache/*-x86_64-darwin.gem
  vendor/npm-packages-offline-cache
]

# Exclude gems from these bundler groups:
set :bundle_without, [:development, :test]

set :application, 'mbis_front'

# Configuration files that are configured from secondary_repo, or created separately
set :secondary_repo_paths, %w[
  config/special_users.production.yml config/admin_users.yml config/odr_users.yml
  config/user_yubikeys.yml config/regular_extracts.csv
]

# Configuration files that are configured from credentials_repoo, or created separately
set :credentials_repo_paths, %w[
  config/credentials.yml.enc
]

# Paths that are symlinked for each release to the "shared" directory:
set :shared_paths, %w[
  config/database.yml
  config/excluded_mbisids.yml.enc
  config/keys
  config/smtp_settings.yml
  config/master.key
  config/certificates
  log
  private/mbis_data
  private/pseudonymised_data
  tmp
] + secondary_repo_paths + credentials_repo_paths

# paths in shared/ that the application can write to:
set :explicitly_writeable_shared_paths, %w[config log tmp tmp/pids]

if secondary_repo && credentials_repo
  set :build_script, <<~SHELL
    set -e
    for fname in #{secondary_repo_paths.collect { |fname| Shellwords.escape(fname) }.join(' ')}; do
      rm -f "$fname"
      svn export --force "#{secondary_repo}/$fname" "$fname"
    done
    for fname in #{credentials_repo_paths.collect { |fname| Shellwords.escape(fname) }.join(' ')}; do
      rm -f "$fname"
      svn export --force "#{credentials_repo}/$fname" "$fname"
    done
  SHELL
else
  set :build_script, <<~SHELL
    echo 'Warning: Cannot connect to secondary_repo / credentials_repo. Configuration'
    echo 'files may be stale, or will need to be specified in environment variables.'
  SHELL
end

set :asset_script, <<~SHELL
  set -e
  cp config/database.yml.sample config/database.yml
  ruby -e "require 'yaml'; puts YAML.dump('production' => { 'secret_key_base' => 'compile_me' })" > config/secrets.yml
  touch config/special_users.production.yml config/admin_users.yml config/odr_users.yml \
        config/user_yubikeys.yml
  printf 'disable-self-update-check true\\nyarn-offline-mirror "./vendor/npm-packages-offline-cache"\\nyarn-offline-mirror-pruning false\\n' > .yarnrc
  RAILS_ENV=production bundle exec rake assets:clobber assets:precompile
  rm config/secrets.yml config/database.yml
SHELL

namespace :delayed_job do
  # Redefine deplayed_job:restart to first sudo to the application user.
  # In Capistrano v2, the original task is replaced.
  desc 'Restart the delayed_job process'
  task :restart, roles: lambda { roles } do
    run "sudo -i -n -u #{application_user} " \
        "bash -c 'cd #{current_path} && #{rails_env} #{delayed_job_command} restart #{args}'"
  end
end

namespace :app do
  desc "Create start/stop scripts in the app user's $HOME directory"
  task :create_sysadmin_scripts, except: { no_release: true } do
    # TODO: Either make task ndr_dev_support:synchronise_sysadmin_scripts create these if
    #       necessary, or move this method into ndr_dev_support gem
    type    = fetch(:daemon_deployment) ? 'god' : 'server'
    scripts = %W[start_#{type}.sh stop_#{type}_gracefully.sh]

    touch_cmd, chmod_cmd =
      if fetch(:out_of_bundle_gems_use_sudo, true)
        ["sudo -i -n -u #{fetch(:application_user)} touch",
         "sudo -i -n -u #{fetch(:application_user)} chmod 764"]
      else
        ['touch', 'chmod 764']
      end
    scripts.each do |script|
      # source = File.join(release_path, 'script', "#{script}.sample")
      dest = File.join(fetch(:application_home), script)

      # Ensure the script exists, with the correct permissions (should be writeable
      # by deployers, but only runnable by the application user, to prevent the wrong user
      # attempting to start the processes.)
      run "#{touch_cmd} #{dest}" # Ensure file exists
      run "#{chmod_cmd} #{dest}" # Set file permissions
    end
  end

  desc <<-DESC
      [internal] Setup shared files for the just deployed release.
  DESC
  task :move_shared, except: { no_release: true } do
    # Move configuration files from deployment directory to shared location
    fnames = (secondary_repo ? secondary_repo_paths : []) +
             (credentials_repo ? credentials_repo_paths : [])
    escaped_fnames = fnames.collect { |fname| Shellwords.escape(fname) }
    run <<~CMD.gsub(/\n */, ' ') # replaces line breaks below with single spaces
      for fname in #{escaped_fnames.join(' ')}; do
        if [ -e "#{release_path}/$fname" ]; then
          mv "#{release_path}/$fname" "#{shared_path}/$fname";
          chgrp "#{application_group}" "#{shared_path}/$fname";
        fi;
      done
    CMD
  end
end

after 'deploy:setup',                       'app:create_sysadmin_scripts'
before 'ndr_dev_support:filesystem_tweaks', 'app:move_shared'

desc 'ensure additional configuration for CentOS deployments'
task :centos_deployment_specifics do
  # On CentOS 7, we need a newer GCC installation to build gems for new ruby versions
  # We'd like to do the following, but scl incorrectly handles double quotes in passed commands:
  # set :default_shell, 'scl enable devtoolset-9 -- sh'
  set :default_shell, <<~CMD.chomp
    sh -c 'scl_run() { echo "$@" | scl enable devtoolset-9 -; }; scl_run "$@"'
  CMD
end

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
  set :out_of_bundle_gems, webapp_deployment ? %w[puma puma-daemon rack nio4r] : %w[]
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
    # You can override the path using e.g. set :pg_conf_path, '/usr/pgsql-9.5/bin/pg_config'
    # otherwise the latest installed version will be used.
    run <<~SHELL
      set -e;
      cd #{release_path};
      pg_conf_path="#{fetch(:pg_conf_path, '')}";
      if [ -z "$pg_conf_path" ]; then
        pg_conf_path=`ls -1d /usr/pgsql-{9,[1-8]*}/bin/pg_config 2> /dev/null | tail -1`;
      fi;
      if [ -n "$pg_conf_path" ]; then
        echo Using pg_conf_path=\"$pg_conf_path\";
        bundle config --local build.pg --with-pg-config="$pg_conf_path";
      fi
    SHELL
  end
end
before 'bundle:install', 'bundle:configure'

after 'ndr_dev_support:prepare' do
  set :synchronise_sysadmin_scripts, webapp_deployment
end

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

# For AWS CodeDeploy deployments, using a local working copy checkout
add_target(:current, :localhost_live, 'localhost', 22, 'mbis_app', true)

%i[mbis_live mbis_beta mbis_god_live mbis_brca_beta].each do |name|
  after name, 'centos_deployment_specifics'
end
