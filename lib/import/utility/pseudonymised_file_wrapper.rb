require 'json'
require 'csv'
require 'pry'

module Import
  module Utility
# Provide the ability to extract fieldnames and create CSV output from .pseudo files
    class PseudonymisedFileWrapper
      def initialize(filename)
        @filename = filename
        @logger = Import::Log.get_auxiliary_logger
      end

      def available_fields
        (@all_fields1 + @all_fields2).sort.uniq
      end

      def process
        line_counter = 1
        processed_lines = []
        all_fields1 = []
        all_fields2 = []
        CSV.foreach(@filename) do |row|
          if row.size == 1
          # Header; do nothing
          elsif row.size == 7
            cur = { map1: JSON.parse(row[4]),
                    map2: JSON.parse(row[6]),
                    id1: row[0],
                    id2: row[1],
                    keys: row[2] }
            processed_lines.push(cur)
            all_fields1.push(*cur[:map1].keys).uniq!
            all_fields2.push(*cur[:map2].keys).uniq!
          else
            @logger.debug "Line #{line_counter} contained unexpected number of fields: #{row.size}"
          end
          line_counter += 1
        end
        @lines = line_counter
        @all_fields1 = all_fields1
        @all_fields2 = all_fields2
        @processed_lines = processed_lines
      end

      def pretty_write
        /(?<base_name>.*)\.(?:csv|(?:zip|xlsx?)\.pseudo)/i.match(@filename)
        target_filename = "#{$LAST_MATCH_INFO[:base_name]}_pretty.csv"
        @logger.debug "Writing output to #{target_filename}"
        CSV.open(target_filename, 'w') do |file|
          headers = (@all_fields1.map { |name| "mapped:#{name}" } +
                     @all_fields2.map { |name| "raw:#{name}" } +
                     %w[pseudo_id1 pseudo_id2 key_bundle])
          file << headers
          @processed_lines.each do |line|
            output_fields = @all_fields1.map { |field| line[:map1][field] } +
                            @all_fields2.map { |field| line[:map2][field] }
            output_fields.push(line[:id1], line[:id2], line[:keys])
            file << output_fields
          end
        end
      end
    end
  end
end
