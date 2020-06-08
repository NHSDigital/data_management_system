module Lookups
  class CommonLawExemption < ApplicationLookup
    scope :s251, -> { where('value ILIKE ?', 'S251%') }
  end
end
