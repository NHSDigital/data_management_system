class HomeController < ApplicationController
  skip_before_action :authenticate_user!, only: [:servicestatus]

  def index; end

  # Display basic service status in HTML or JSON
  # For automatic status detection, the service is working correctly if the resulting string has
  # a key 'status' and a value starting 'OK'.
  # Also allows minimal admin actions (e.g. restarting webapps for logged in developers
  # or while the service is idle)
  def servicestatus
    webapp_status = if ENV['RAILS_MASTER_KEY'].blank?
                      'OK: no RAILS_MASTER_KEY configured'
                    else
                      'OK (using RAILS_MASTER_KEY)'
                    end
    revision_and_timestamp = lambda do |dir|
      fname = File.join(dir, 'REVISION') # for capistrano deployments
      File.exist?(fname) ? [File.read(fname).chomp, File.mtime(fname).getlocal] : ['Unknown', nil]
    end
    running_revision, running_revision_time = revision_and_timestamp.call(Rails.root)
    current_revision, current_revision_time = \
      revision_and_timestamp.call(Rails.root.join('../../current'))
    status = { 'status' => webapp_status,
               'running_revision' => running_revision,
               'running_revision_time' => running_revision_time,
               'current_revision' => current_revision,
               'current_revision_time' => current_revision_time,
               'system_stack' => Mbis.stack,
               'system_start_time' => ::TIME_PROCESS_STARTED.getlocal,
               'system_time' => Time.now.getlocal,
               'logged_in' => user_signed_in?,
               'database_migration_latest' => ActiveRecord::Migrator.current_version }
    respond_to do |format|
      format.json do
        render json: status
      end
      format.html do
        @status = status
      end
    end
  end
end
