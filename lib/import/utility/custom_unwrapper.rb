require 'json'
require 'csv'
require 'pry'
require 'logger'
# Similar to the wrapper for .pseudo files, but designed to be used on the CSV
# output of SQL queries which include the raw records that we want to inspect
module Import
  module Utility
    class CustomUnwrapper
      def initialize(filename)
        @filename = filename
        @logger = Logger.new(STDOUT) # Log.get_auxiliary_logger
      end

      def available_fields
        @all_fields1.sort.uniq
      end

      def process
        line_counter = 1
        processed_lines = []
        all_fields1 = []
        CSV.foreach(@filename) do |row|
          #      if row.size == 1
          # Header; do nothing
          if row.size == 1
            cur = {
              dna: row[0],
              provider: row[1],
              gene: row[3],
              map1: JSON.parse(row[0].gsub(/=>/, ':'))
            }
            processed_lines.push(cur)
            all_fields1.push(*cur[:map1].keys).uniq!
          else
            @logger.debug "Line #{line_counter} contained unexpected number of fields: #{row.size}"
          end
          line_counter += 1
        end
        @lines = line_counter
        @all_fields1 = all_fields1
        @processed_lines = processed_lines
      end

      def pretty_write
        /(?<base_name>.*)\.(?:csv|xlsx?\.pseudo)/i.match(@filename)
        target_filename = "#{$LAST_MATCH_INFO[:base_name]}_pretty2.csv"
        @logger.debug "Writing output to #{target_filename}"
        CSV.open(target_filename, 'w') do |file|
          headers = ( # %w(pseudo_id1 pseudo_id2 servicereportidentifier) +
                     @all_fields1.map { |name| "mapped:#{name}" }
                   )
          file << headers
          @processed_lines.each do |line|
            output_fields = [] # [line[:dna], line[:provider], line[:gene]]
            output_fields.push(*@all_fields1.map { |field| line[:map1][field] })
            file << output_fields
          end
        end
      end
    end
  end
end

# ofw = Import::Utility::CustomUnwrapper.new(ARGV[0])
# ofw.process
# ofw.pretty_write
