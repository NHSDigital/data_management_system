module Xsd
  # Build a sample XML for a dataset version from the database
  module XmlHeader
    DATA_DICTIONARY = 'http://www.datadictionary.nhs.uk/messages/'.freeze

    def header_one
      "#{name}:#{name}"
    end

    def header_three
      "xmlns:#{name}"
    end

    def header_four
      DATA_DICTIONARY + "#{name}-v#{schema_version_format}"
    end
  end
end
