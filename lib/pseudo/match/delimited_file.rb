module Pseudo
  module Match
    # Match a CSV file against Ppatient records, and return the list of Ppatientids.
    class DelimitedFile
      HEADER_ROW = %w(rowid nhsnumber birthdate current_postcode).freeze
      # Equivalent, allowed values for each of the header columns
      HEADER_VARIANTS = [%w[rowid patientid],
                         %w[nhsnumber],
                         %w[birthdate dateofbirth],
                         %w[current_postcode]].freeze

      def initialize(infile, outfile, e_types, key_names, logger)
        @in_csv = CSV.new(infile, row_sep: :auto)
        @out_csv = CSV.new(outfile)
        @e_types = e_types
        @key_names = key_names
        @logger = logger
        @out_csv << %w(pseudo_id1 rowid ppatient_id match)
      end

      def match
        @in_csv.each_with_index do |row, i|
          next if i.zero? && row.zip(HEADER_VARIANTS).
                  all? { |col, allowed| allowed.include?(col.to_s.downcase) }
          raise("Invalid CSV row #{i + 1}: too many columns, expected up to 4") unless row.size <= 4

          begin
            match_one(row[0], row[1], row[3], row[2])
          rescue => e
            raise e.message + " on row #{i + 1}"
          end
        end
      end

      private

      def match_one(rowid, nhsnumber, postcode, birthdate)
        postcode ||= ''
        ppats = Ppatient.find_matching_ppatients(nhsnumber, postcode, birthdate,
                                                 @key_names, e_types: @e_types)
        @logger&.warn { [rowid, nhsnumber, birthdate, postcode] }
        @logger&.warn do
          "Matched #{ppats.size} Ppatient records with pseudo_id1 " \
          "#{ppats.collect(&:pseudo_id1).inspect}"
        end
        ppats.each do |pat|
          matched = pat.match_demographics(nhsnumber, postcode, birthdate)
          @logger&.warn { "Unpacked demographics: #{pat.demographics}" }
          @logger&.warn { "Matched: #{matched}" }
          @out_csv << [pat.pseudo_id1, rowid, pat.id, matched]
        end
      end
    end
  end
end
