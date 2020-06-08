module Lookups
  # Yes/No/Maybe lookup table
  class Proposition < ApplicationLookup
    scope :binary, -> { where(value: %w[Yes No]) }
  end
end
