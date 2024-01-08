desc 'Run basic smoke tests'
# Tasks listed here should all run without a database connection:
task smoke_test: %w[smoke_test:eager_load]

namespace :smoke_test do
  desc 'Ensure application codebase eager loads without DB connection'
  task eager_load: :environment do
    # Ensure there are no existing connections...
    raise 'Already connected!' if ActiveRecord::Base.connected?

    Rails.application.eager_load!
  end
end
