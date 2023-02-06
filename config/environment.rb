# Load the Rails application.
require_relative 'application'
require File.expand_path('../lib/application_constants', __dir__)

# Initialize the Rails application.
Rails.application.initialize!

include ApplicationConstants
