module Xsd
  # Build an XSD for a dataset and version
  module Header
    PROVIDERS = {
      w3: {
        schema: 'http://www.w3.org/2001/XMLSchema'.freeze
      }.freeze
    }.freeze

    def ns(namespace, provider, key, split_to_files)
      header_options = {
        w3_reference_key(namespace) => w3_reference_value(provider, key),
        dataset_key => xmlns,
        version: semver_version,
        id: xsd_id,
        xmlns: xmlns,
        targetNamespace: xmlns
      }
      header_options[:finalDefault] = 'extension' if split_to_files
      header_options
    end

    def w3_reference_key(namespace)
      'xmlns:' + namespace
    end

    def w3_reference_value(provider, key)
      PROVIDERS[provider][key]
    end

    def dataset_key
      'xmlns:' + dataset_name
    end

    def xsd_id
      dataset_name + '_XMLSchema-v' + semver_version
    end

    def xmlns
      'http://www.datadictionary.nhs.uk/messages/' + dataset_name + '-v' + semver_version
    end
  end
end
