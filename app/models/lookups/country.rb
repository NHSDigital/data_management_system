module Lookups
  class Country < ApplicationLookup
    def self.sorted_dropdown
      top_of_list_ids = %w[XKU]
      top_of_list = top_of_list_ids.map { |id| Country.find id }
      rest_of_list = Country.all - top_of_list
      [top_of_list, rest_of_list].flatten
    end
  end
end
