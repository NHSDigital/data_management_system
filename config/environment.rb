# Load the Rails application.
require_relative 'application'
require File.expand_path('../../lib/application_constants', __FILE__)

# Initialize the Rails application.
Rails.application.initialize!

include ApplicationConstants
