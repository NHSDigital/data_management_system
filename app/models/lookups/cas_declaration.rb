# CAS Declaration lookup model
module Lookups
  class CasDeclaration < ApplicationLookup
    default_scope { where('sort is null or sort > 0').order(:sort, :id) }
  end
end
