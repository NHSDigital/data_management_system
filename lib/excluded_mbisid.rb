# Provide non-inspectable list of MBISIDs to exclude.
# (These are useful where individual historical death records are known to be inaccurate,
# e.g. for non-cancer deaths)
module ExcludedMbisid
  MBISID_FORMAT = /\A[a-z0-9]*\z/i.freeze
  DUMMY_MBISID = 'MBIS0ID0TO0EXCLUDE'.freeze # Dummy MBIS ID to test exclusions
  EXCLUSION_FILENAME = 'config/excluded_mbisids.yml.enc'.freeze

# Return true if the MBISID is on the exclusion list.
=begin
To exclude someone on MBIS, run:
  bin/rake export:exclude_mbisid
=end
  def self.excluded_mbisid?(str)
    @excluded_mbisids ||= fetch_excluded_mbisids
    @excluded_mbisids.include?(str)
  end

  # Private method, to return list of MBISIDs to exclude
  private_class_method def self.fetch_excluded_mbisids
    return [DUMMY_MBISID] if Rails.env.test? # Dummy MBISIDs for testing

    excluded_mbisid_key = Rails.application.credentials.excluded_mbisid_key
    if excluded_mbisid_key
      ENV['EXCLUDED_MBISIDS_KEY'] = excluded_mbisid_key
      mbisids = Rails.application.encrypted(EXCLUSION_FILENAME,
                                            env_key: 'EXCLUDED_MBISIDS_KEY').excluded
      ENV.delete('EXCLUDED_MBISIDS')
    else
      mbisids = []
    end
    if mbisids.blank? && !Rails.env.development?
      Rails.logger.warn('ExcludedMbisid.fetch_excluded_mbisids: ' \
                        'No excluded MBISIDs configured')
    end
    (mbisids || []).to_set
  end

  # Add an MBISID to the exclusion file, including a one-line comment
  def self.exclude_mbisid!(mbisid, comment = nil)
    raise 'Invalid mbisid' unless MBISID_FORMAT.match?(mbisid)
    raise 'Invalid comment' if comment.include?("\n")

    comment = '  # ' + comment if comment # Add YAML comment marker to comment
    excluded_mbisid_key = Rails.application.credentials.excluded_mbisid_key
    unless excluded_mbisid_key
      raise 'Missing excluded_mbisid_key: Rails.application.credentials.excluded_mbisid_key ' \
            'should be a 32 character hex string'
    end

    ENV['EXCLUDED_MBISIDS_KEY'] = excluded_mbisid_key
    exclusion_config = Rails.application.encrypted(EXCLUSION_FILENAME,
                                                   env_key: 'EXCLUDED_MBISIDS_KEY')
    config_yaml = exclusion_config.read
    config_yaml = if config_yaml.blank?
                    <<~EMPTY_CONFIG
                      # MBISIDs to be excluded
                      excluded:
                    EMPTY_CONFIG
                    # Will append e.g.
                    # - MBIS0ID0TO0EXCLUDE  # Dummy MBISID for testing
                  else
                    config_yaml.sub(/[\n]*\z/, "\n") # Finish with exactly 1 newline
                  end
    config_yaml += "  - '#{mbisid}'#{comment}\n"
    exclusion_config.write(config_yaml)
    ENV.delete('EXCLUDED_MBISIDS')
    @excluded_mbisids = nil # Reset cache
  end
end
