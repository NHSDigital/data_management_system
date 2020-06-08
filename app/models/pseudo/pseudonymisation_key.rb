module Pseudo
  # pseudonymisation key table
  class PseudonymisationKey < ActiveRecord::Base
    belongs_to :zprovider, optional: true
    belongs_to :ze_type, foreign_key: 'e_type', optional: true
  end
end
