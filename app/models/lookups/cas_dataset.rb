# CAS Dataset lookup model
module Lookups
  class CasDataset < ApplicationLookup
    default_scope { where('sort is null or sort > 0').order(:sort, :id) }
  end
end
