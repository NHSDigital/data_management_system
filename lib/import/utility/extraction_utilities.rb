require 'csv'
# Common location for useful functions and constants
module Import
  module Utility
    # Extraction utilities code
    module ExtractionUtilities
      # Common utility methods
      class CommonUtility
        # TODO: this pile of regexs is a mess and needs to be cleaned up
        GENE_ONLY = '(?<location>c\.[^ \.]+)'.freeze
        GENE_LOC = "#{GENE_ONLY} ?(?<protein>\(p\.[^\)\(]*\))?".freeze
        BRCA_BASE = 'br?c?a?'.freeze
        BRCA     = BRCA_BASE + '(?<brca>1|2)'.freeze
        EXON_LOC = 'exons? (?<exons>\d+[a-z0-9]*(?:-\d+[a-z0-9]*)?)'.freeze
        VARIANT  = '(?:familial)?(?<variantclass>(?: likely) pathogenic)?' \
        ' BRCA(?<brca>1|2) (?:mutation|sequence variant)'.freeze
        ZYGOSITY = '(?<zygosity>[a-z]+)zygous'.freeze
        GENE_LOCATION = '(?<location>c\.[^\s\.]+)\s?(?<protein>\(p\.[^)]*\))?'.freeze
        EXON_LOCATION = 'exons?\s(?<exons>\d+[a-z0-9]*(?:-\d+[a-z0-9]*)?)'.freeze
        LOCATION_REGEX = /(#{GENE_LOCATION}(?:\sin\s(?:brca(?:1|2)\s)?#{EXON_LOCATION})?|
                         #{EXON_LOCATION})/ix

        ZYGOSITY_REGEX = /(?<zygosity>[a-z]+)zygous/

        def extract_single_mutation(report_string, genotype)
          return false if report_string.nil?

          if report_string.scan(LOCATION_REGEX).chunk { |x| x }.map(&:first).size == 1
            matches = report_string.match(LOCATION_REGEX)
            genotype.add_gene_location(matches[:location])
            genotype.add_protein_impact(matches[:protein])
            genotype.add_exon_location(matches[:exons])
            if report_string.scan(ZYGOSITY_REGEX).size == 1
              matches = report_string.match(ZYGOSITY_REGEX)
              genotype.add_zygosity(matches[:zygosity])
            end
            true
          else
            false # TODO: clean up
          end
        end

        def extract_brca(string_list)
          string_list.
            reject(&:nil?).
            map { |entry| entry.scan(/br?c?a?(?<brca>1|2)/i).map { |match| match[0] } }.
            flatten.
            reject(&:nil?).
            map(&:to_i).
            sort.
            chunk { |n| n }.
            map(&:first)
        end
      end

      # TODO: the accuracy of this extractor could be notably improved if it can be converted
      #       to interpret the formal grammar of HGSV nomenclature, as several HGSV python
      #       packages do. This applies mostly to standarising c. and p. forms and catching
      #       some edge cases/unusual mutations which would currently be rejected.

      # Provide utilities to extract c., p., and exon-based location information from
      # raw strings
      class LocationExtractor < CommonUtility
        CDNA = '\\*?\\d+((_|-|\\+)\\d+)? ?([a-z]+(?:>|<)[a-z]+|(del|dup|ins)' \
        ' ?(?:[atcg]*|[0-9]*))*(?=(?:\\s|$|\\()|,)'.freeze

        def initialize(write_csv: false)
          # TODO: this really needs to write to a more sensible place
          @write_csv = write_csv
          @csv = CSV.open('extractions.csv', 'a') if @write_csv
          super
        end

        # Prefer the version below, which produces type-wrapped results
        def extract(raw_string)
          case raw_string
          when /^c\.? *(?<cdna>#{CDNA}),?;? *(?:\(?p\. ?\(?(?<protein>[^)]+)\)?)?(?<remainder>.*)/i
            if @write_csv
              @csv << ["c.#{$LAST_MATCH_INFO[:cdna]}",
                       "p.#{$LAST_MATCH_INFO[:protein]}",
                       $LAST_MATCH_INFO[:remainder].strip.to_s]
            end
            { cdna: $LAST_MATCH_INFO[:cdna].tr('<', '>'),
              protein: $LAST_MATCH_INFO[:protein],
              remainder: $LAST_MATCH_INFO[:remainder] }
          # when /#{EXON_LOC}/i
          #   # For now, just placeholder...
          #   {}
          else
            {}
          end
        end

        # Experimental new version
        def extract_type(raw_string)
          case raw_string
          when /^c\.?\s*(?<cdna>#{CDNA}),?;?\s*(?:\(?p\.\s?\(?(?<protein>[^)\s]+(?:\s?fs(?:\*|
            Ter)\d*))\)?)?(?<remainder>.*)/ix
            if @write_csv
              @csv << ["c.#{$LAST_MATCH_INFO[:cdna]}",
                       "p.#{$LAST_MATCH_INFO[:protein]}",
                       $LAST_MATCH_INFO[:remainder].strip.to_s]
            end
            ExactLocation.new($LAST_MATCH_INFO[:cdna],
                              $LAST_MATCH_INFO[:protein],
                              $LAST_MATCH_INFO[:remainder])
          when /(?<del_dup1>del|dup)?\s?(?:exons?|exon\(s\)|ex|
            x)\s?(?<exons>\d+[0-9]*(?:[a-z](?![a-z]))?\s?(?:(?:to|-)\s?(?:\d+(?:[a-z]\s)?|
            \d+))?)\s?(?<del_dup2>del(?:etion)?|dup(?:lication)?)?$/ix
            # For now, just placeholder...
            mods = [$LAST_MATCH_INFO[:del_dup1],
                    $LAST_MATCH_INFO[:del_dup2]].reject(&:nil?)
            @logger.info "Too many modifications found in: #{raw_string}" if mods.size > 1
            ExonLocation.new($LAST_MATCH_INFO[:exons], mods.first)
          else
            ParseFailure.new(raw_string)
          end
        end
      end

      # Stores the c. and p. mutation info from the parse
      class ExactLocation
        def initialize(cdna, protein = nil, remainder = nil)
          @cdna = cdna
          @protein = protein
          @remainder = remainder
        end
        attr_reader :cdna, :protein, :remainder
      end

      # Store location parsed at exon level only (just a stub)
      class ExonLocation
        def initialize(exon, mods)
          @exon = exon
          @mods = mods
        end

        attr_reader :exon, :mods
      end

      # Wrapper for the unparsable 'genotype'
      class ParseFailure
        def initialize(raw)
          @raw = raw
        end
        attr_reader :raw
      end

      if __FILE__ == $PROGRAM_NAME
        extractor = LocationExtractor.new(write_csv: false)
        extractor.extract('c.777_888delA')
      end
    end
  end
end
