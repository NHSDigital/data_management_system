module Pseudo
  # Helper methods, for inclusion into rake tasks
  module RakeHelper
    # Helpers to export plain-text demographics based on pseudoid linkage against
    # pseudonymised data
    module MatchDemographics
      # Expand 'allow_fuzzy' command line options into a list of accepted match scores
      def self.expand_allow_fuzzy_options(allow_fuzzy)
        if allow_fuzzy.blank?
          [:perfect]
        else
          allow_fuzzy.split(',').collect do |val|
            case val
            when 'all' then %i[veryfuzzy perfect fuzzy fuzzy_postcode]
            when 'true', 'veryfuzzy' then %i[veryfuzzy perfect fuzzy]
            when 'fuzzy' then %i[perfect fuzzy]
            when 'fuzzy_postcode' then [:fuzzy_postcode]
            when 'false', 'perfect' then [:perfect]
            when 'none' then []
            else raise(ArgumentError, "Invalid allow_fuzzy parameter value #{val.inspect}")
            end
          end.flatten.uniq
        end
      end

      # Export plain-text demographics based on pseudoid linkage against pseudonymised data
      # Produces a CSV file with the following columns:
      # rowid,nhsnumber,birthdate,postcode,match_status,ppatient_id,e_batch_provider,
      # original_filename,demographics_json
      # plus any fields listed in optional extract_fields parameter
      def self.export_demographics(infile:, outfname:, e_types:, key_names:, logger:,
                                   match_scores:, extract_fields: [])
        # TODO: Support block argument to Pseudo::Match::DecryptDemographics#match
        matches = Pseudo::Match::DecryptDemographics.new(e_types, key_names, logger).
                  match(infile, match_scores) # list of [rowid, ppatient, match_status]
        # TODO: Allow variable verbosity, use logger&.warn
        puts "Found #{matches.count} matching patient records to extract"
        if matches.empty?
          puts 'Warning: nothing to extract, not creating empty output file'
          # TODO: Remove any existing file
          return
        end
        CSV.open(outfname, 'wb') do |csv_out|
          csv_out << %w[rowid nhsnumber birthdate postcode match_status ppatient_id
                        e_batch_provider original_filename demographics_json] +
                     extract_fields.collect { |field| "extracted_#{field}" }
          matches.each do |rowid, nhsnumber, postcode, birthdate, ppat, match_status|
            original_filename = ppat.e_batch.original_filename
            demographics_json = ppat.demographics.to_json
            extra_fields = extract_fields.collect { |field| ppat.demographics[field] }
            csv_out << [rowid, nhsnumber, birthdate, postcode, match_status, ppat.id,
                        ppat.e_batch.provider, original_filename, demographics_json] + extra_fields
          end
        end
      end
    end
  end
end
