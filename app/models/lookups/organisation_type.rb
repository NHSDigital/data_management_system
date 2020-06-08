module Lookups
  class OrganisationType < ApplicationLookup
    def self.other
      find_by(value: 'Other')
    end
  end
end
