module Pseudo
  module Match
    # Match a CSV file against Ppatient records, and return unlocked ppatients so that demographics
    # can be extracted
    class DecryptDemographics < Ppatients
      # Returns a list of rowid, ppatient, match_status] for the ppatient records
      # [inherited from superclass]
      # def match(infile, match_scores = nil)
      # end

      private

      # Returns a list of [rowid, nhsnumber, postcode, birthdate, ppat, match_status] for the
      # ppatient records that match the given demographics, with one of the given match_scores
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
          next if match_scores&.exclude?(matched)

          [rowid, nhsnumber, postcode, birthdate, pat, matched]
        end.compact
      end
    end
  end
end
