# Closure reason lookup model
module Lookups
  class ClosureReason < ApplicationLookup
    scope :rejectable, -> {
      where.not(value: ['Proceeding to application', 'Proceeding to amendment'])
    }
  end
end
