module Pseudo
  module Match
    # Match a CSV file against Ppatient records, and return the list of Ppatientids.
    class Ppatients
      # TODO: Refactor with Pseudo::Match::DelimitedFile
      HEADER_ROW = %w(rowid nhsnumber birthdate current_postcode).freeze
      # Equivalent, allowed values for each of the header columns
      HEADER_VARIANTS = [%w[rowid patientid],
                         %w[nhsnumber],
                         %w[birthdate dateofbirth],
                         %w[current_postcode postcode]].freeze

      def initialize(e_types, key_names, logger)
        @e_types = e_types
        @key_names = key_names
        @logger = logger
      end

      # Returns a list of [pseudo_id1, rowid, ppatientid, match_status] for the ppatient records
      # (or whatever #match_one returns)
      def match(infile, match_scores = nil)
        result = []
        in_csv = CSV.new(infile, row_sep: :auto)
        in_csv.each_with_index do |row, i|
          next if i.zero? && row.zip(HEADER_VARIANTS).
                  all? { |col, allowed| allowed.include?(col.to_s.downcase) }
          raise("Invalid CSV row #{i + 1}: too many columns, expected up to 4") unless row.size <= 4

          begin
            result += match_one(row[0], row[1], row[3], row[2], match_scores)
          rescue => e
            raise e.message + " on row #{i + 1}"
          end
        end
        result
      end

      private

      # Returns a list of [pseudo_id1, rowid, ppatientid, match_status] for the ppatient records
      # that match the given demographics, with one of the given match_scores
      def match_one(rowid, nhsnumber, postcode, birthdate, match_scores)
        postcode ||= ''
        ppats = Ppatient.find_matching_ppatients(nhsnumber, postcode, birthdate,
                                                 @key_names, e_types: @e_types)
        @logger&.warn { [rowid, nhsnumber, birthdate, postcode] }
        @logger&.warn do
          "Matched #{ppats.size} Ppatient records with pseudo_id1 " \
          "#{ppats.collect(&:pseudo_id1).inspect}, pseudo_id2 " \
          "#{ppats.collect(&:pseudo_id2).inspect}"
        end
        ppats.collect do |pat|
          matched = pat.match_demographics(nhsnumber, postcode, birthdate)
          @logger&.warn { "Unpacked demographics: #{pat.demographics}" }
          @logger&.warn { "Matched: #{matched}" }
          [pat.pseudo_id1, rowid, pat.id, matched] unless match_scores&.exclude?(matched)
        end.compact
      end
    end
  end
end
