require 'csv'
require 'pry'
# Sometimes labs just write the wrong thing in a field, this class allows us
# patch such errors before they reach the main extraction framework
module Import
  module Brca
    module Core
      # Wrapper object for storing correction information
      class Correction
        def initialize(file_name,
                       line_num,
                       id1,
                       id2,
                       field_name,
                       old_value,
                       new_value,
                       map_category)
          @file_name = file_name
          @line_num = line_num
          @id1 = id1
          @id2 = id2
          @field_name = field_name
          @old_value = old_value
          @new_value = new_value
          @mapped = map_category.downcase.strip == 'mapped'
        end

        def apply(field_map)
          cur_val = field_map[@field_name]
          if cur_val == @old_value
            field_map[@field_name] = @new_value
            true
          else
            @logger.warn "Correction is invalid; unexpected old value in field: #{cur_val}"
            false
          end
        end
      end
    end
  end
end

# Format:
# file_name | line_num | id1 | id2 | field_name | old_value | new_value
