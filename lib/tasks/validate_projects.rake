# Daily task to look for projects that are expiring or have expired

namespace :validate_projects do
  desc 'Daily job to check status of projects approaching expiration'
  task daily_checks: :environment do
    # looks for projects that have past expiry date
    Project.check_and_set_expired_projects

    # looks for projects that might be expiring soon
    Project.check_for_expiring_projects
  end
end

