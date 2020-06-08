module Lookups
  class LawfulBasis < ApplicationLookup
    scope :article6, -> { where('value ILIKE ?', 'Art. 6%') }
    scope :article9, -> { where('value ILIKE ?', 'Art. 9%') }
  end
end
