# Application-wide constants
module ApplicationConstants
  MIGRATION_DATABASE_PATTERN = /(_development)/ unless defined?(MIGRATION_DATABASE_PATTERN)
end
