
module Import
  include ExtractionUtilities
  module Colorectal
    module Providers
      module Leeds
        module ReportExtractor
        # Parent class which encapsulates parsing logic associated with common Leeds
        # genotype forms
          class GenotypePattern
            def initialize
              @failed_report_parse_counter = 0
              @report_parse_attempt_counter = 0
              @logger = Log.get_logger
            end

            attr_reader :failed_report_parse_counter

            def valid?(genotype)
              return self.class::VALID_REGEX.match(genotype)
            end

            def extract(genotype_string, report_string, genotype)
              @report_parse_attempt_counter += 1
              [genotype]
            end

            def performance_summary
              @logger.info "#{self.class} failed to parse #{@failed_report_parse_counter} of #{@report_parse_attempt_counter} reports attempted"
            end
          end

          class AJNegative < GenotypePattern
            VALID_REGEX = /(?:predictive )?aj(?: pre-screen(?:#{"/"}conf)?)? neg(?: 3seq)?/i
            # TODO: check for conf substring, and add moleculartesting type based on that? We are
            # currently missing some
            def extract(genotype_string, report_string, genotype)
              @report_parse_attempt_counter += 1
              genotype.add_status('neg')
              brcas = extract_brca([report_string])
              if brcas.size == 1
                genotype.add_gene(brcas[0])
                [genotype]
              elsif
                genotype2 = genotype.dup
                genotype.add_gene(brcas[0])
                genotype2.add_gene(brcas[1])
                [genotype,genotype2]
              else
                [genotype]
              end
            end
          end

          class AJPositive < GenotypePattern
            VALID_REGEX = /(?:predictive )?aj(?: B(?:1|2))?(?: pre-screen(?:#{"/"}conf)?)? pos(?: 3seq)?/i

            def extract(genotype_string, report_string, genotype)
              @report_parse_attempt_counter += 1
              genotype.add_status('pos')

              if extract_single_mutation(report_string, genotype)
                brcas = extract_brca([report_string, genotype_string])
                if brcas.size == 1
                  genotype.add_gene(brcas[0])
                else
                  @failed_report_parse_counter += 1
                end
              else
                @failed_report_parse_counter += 1
              end
              [genotype]
            end
          end

          # Generate records to indicate that both BRCA variants are normal
          class DoubleNormal < GenotypePattern
            SAFELIST = %w(b1 b2 normal unaffected) .freeze
            EXCLUDEABLE = ([' '] + %w(/ NGS MLPA seq and - patient)).map(&:downcase)

            def performance_summary
              @logger.info "#{self.class} As both genes are normal, no need to parse the report for #{@report_parse_attempt_counter} records"
            end

            def valid?(genotype)
              return false if genotype.nil?
              words = genotype.split(Regexp.new('(,| |/)'))
              trimmed_words = words.map(&:downcase).
              reject { |x| EXCLUDEABLE.include? x }
              all_safe = trimmed_words.
              reject { |x| SAFELIST.include? x }.
              empty? # TODO: flag/error if false?
              all_present = trimmed_words.include?('b1') &&
              trimmed_words.include?('b2') &&
              (trimmed_words.include?('normal') || trimmed_words.include?('unaffected'))
              all_safe && all_present
            end

            def extract(genotype_string, _report_string, genotype)
              case genotype_string
              when /mlpa/i then genotype.add_method($&)
              when /ngs/i  then genotype.add_method($&)
              when /seq/i  then genotype.add_method($&)
              end
              genotype.add_status(1)
              @report_parse_attempt_counter += 1

              # Since both variants are normal, we want to generate a testresult for each
              genotype2 = genotype.dup
              genotype.add_gene(1)
              genotype2.add_gene(2)
              [genotype, genotype2]
            end
          end

          # Extract information from predictive tests
          class Predictive < GenotypePattern
            VALID_REGEX = /predictive b(?:rca)?(?<brca>1|2) (?<method>seq|ngs|mlpa) (?<status>pos|neg)/i

            REPORT_REGEX_NEGATIVE = /.*(?:familial)?(?<variantclass>(?: likely) pathogenic)? BRCA(?<brca>1|2) (?:mutation|sequence variant) ? (?<location>c\.[^ \.]+) (?<protein>\(p\..*\))? ?is absent.*/i
            #  @reportRegexPositive = /.*patient is (?:hetero|homo)zygous for the pathogenic BRCA(1|2) mutation (c\.[^ \.]+).*/i
            REPORT_REGEX_POSITIVE = /.*patient is (?<zygosity>hetero|homo)zygous for the ?(?<family> familial)?(?<variantclass>(?: likely)?(?: pathogenic)?) BRCA(?<brca>1|2) (?:mutation|sequence variant) ? (?<location>c\.[^ \.]+).*/i
            REPORT_REGEX_INHERITED = /has (?<status>not )?inherited the (?<family>familial )?BRCA(?<brca>1|2) (?:mutation|sequence variant) ? (?<location>c\.[^ \.]+) (?<protein>\(p\..*\))?/i
            MLPA_NEGATIVE = /mlpa.*the(?<family> familial)?(?<variantclass> (?:likely )?pathogenic)? BRCA(?<brca>1|2) (?<mutationtype>deletion|duplication) of exons? (?<exons>\d+[a-z0-9]*(?:-\d+[a-z0-9]*)?) is absent/i
            INHERITED_EXON = /has (?<status>not )?inherited the (?<family>familial )?(?<variantclass> (?:likely )?pathogenic )?BRCA(?<brca>1|2) (?<mutationtype>deletion|duplication) of exons? (?<exons>\d+[a-z0-9]*(?:-\d+[a-z0-9]*)?)/i

            def extract(genotype_string, report_string, genotype)
              @report_parse_attempt_counter += 1
              if self.class::VALID_REGEX.match(genotype_string)
                genotype.add_gene($LAST_MATCH_INFO[:brca])
                genotype.add_method($LAST_MATCH_INFO[:method])
                genotype.add_status($LAST_MATCH_INFO[:status])
              end
              if genotype.positive?
                @failed_report_parse_counter += 1 unless extract_single_mutation(report_string, genotype)
              else
                case report_string.gsub('\n', '')
                when self.class::REPORT_REGEX_POSITIVE then
                  # TODO: add familial
                  Maybe($LAST_MATCH_INFO[:zygosity]).map { |x| genotype.add_zygosity(x) }
                  Maybe($LAST_MATCH_INFO[:location]).map { |x| genotype.add_gene_location(x) }
                  Maybe($LAST_MATCH_INFO[:brca]).map { |x| genotype.add_gene(x) }
                  Maybe($LAST_MATCH_INFO[:variantclass]).map { |x| genotype.add_variant_class(x) }
                when self.class::REPORT_REGEX_NEGATIVE then
                  # Maybe($LAST_MATCH_INFO[:zygosity]).map { |x| genotype.add_zygosity(x) }
                  #Maybe($LAST_MATCH_INFO[:location]).map { |x| genotype.add_gene_location(x) }
                  Maybe($LAST_MATCH_INFO[:brca]).map { |x| genotype.add_gene(x) }
                  #Maybe($LAST_MATCH_INFO[:variantclass]).map { |x| genotype.add_variant_class(x) }
                  #Maybe($LAST_MATCH_INFO[:protein]).map { |x| genotype.add_protein_impact(x) }
                when self.class::REPORT_REGEX_INHERITED then
                  Maybe($LAST_MATCH_INFO[:location]).map { |x| genotype.add_gene_location(x) }
                  Maybe($LAST_MATCH_INFO[:protein]).map { |x| genotype.add_protein_impact(x) }
                  Maybe($LAST_MATCH_INFO[:brca]).map { |x| genotype.add_gene(x) }
                when self.class::MLPA_NEGATIVE then
          
                  #Maybe($LAST_MATCH_INFO[:variantclass]).map { |x| genotype.add_variant_class(x) }
                  Maybe($LAST_MATCH_INFO[:brca]).map { |x| genotype.add_gene(x) }
                  #Maybe($LAST_MATCH_INFO[:mutationtype]).map { |x| genotype.add_variant_type(x) }
                  #Maybe($LAST_MATCH_INFO[:exons]).map { |x| genotype.add_exon_location(x) }
                when self.class::INHERITED_EXON then
                  # Maybe($LAST_MATCH_INFO[:status]).map { |x| genotype.add_status(x) }
                  # TODO: make this fail loudly if contradictory
                  Maybe($LAST_MATCH_INFO[:variantclass]).map { |x| genotype.add_variant_class(x) }
                  Maybe($LAST_MATCH_INFO[:brca]).map { |x| genotype.add_gene(x) }
                  Maybe($LAST_MATCH_INFO[:mutationtype]).map { |x| genotype.add_variant_type(x) }
                  Maybe($LAST_MATCH_INFO[:exons]).map { |x| genotype.add_exon_location(x) }
                else
                  @failed_report_parse_counter += 1
                end
              end
              [genotype]
            end
          end

          # Extract information from results on tests intended to confirm
          class Confirmation < GenotypePattern
            VALID_REGEX = /confirmation b(?:rca)?(?<brca>1|2) (?<method>seq|ngs|mlpa) (?<status>pos|neg)/i
            def initialize
              # variant = '(?:familial)?(?<variantclass>(?: likely) pathogenic)?' \
              #           ' BRCA(?<brca>1|2) (?:mutation|sequence variant)'
              @single = /patient is #{Import::CommonUtility::ZYGOSITY} for the #{Import::CommonUtility::VARIANT} #{Import::CommonUtility::GENE_LOC}/i
              super
            end

            # TODO: add molecular testing type
            def extract(genotype_string, report_string, genotype)
              @report_parse_attempt_counter += 1
              if self.class::VALID_REGEX.match(genotype_string)
                genotype.add_gene($LAST_MATCH_INFO[:brca])
                genotype.add_method($LAST_MATCH_INFO[:method])
                genotype.add_status($LAST_MATCH_INFO[:status])
              end

              if genotype.positive?
                if extract_single_mutation(report_string, genotype)
          
                else
                  @logger.debug report_string
                  @failed_report_parse_counter += 1
                end
              end
              [genotype]
            end
          end

          # Extract severity and method information from variant class genotypes
          class VariantClass < GenotypePattern
            VALID_REGEX = /b(?:rca)?(?<brca>1|2) class (?<class>[1-5]a?) (uv|new)(?: unaffected patient)?/i

            def extract(genotype_string, report_string, genotype)
              @report_parse_attempt_counter += 1
              self.class::VALID_REGEX.match(genotype_string)
              if genotype.add_gene($LAST_MATCH_INFO[:brca])
                genotype.add_variant_class($LAST_MATCH_INFO[:class].to_i)
              end

              @failed_report_parse_counter += 1 unless extract_single_mutation(report_string, genotype)
              [genotype]
            end
          end

          # Extract severity and method information from variant genotypes
          class VariantSeq < GenotypePattern
            VALID_REGEX = /(?<method>ngs )?b(?:rca)?(?<brca>1|2) seq variant(?: - class (?<variantclass>[1-5]))?/i

            def extract(genotype_string, report_string, genotype)
              @report_parse_attempt_counter += 1
              genotype_matches = self.class::VALID_REGEX.match(genotype_string)
              genotype.add_method(genotype_matches[:method])
              genotype.add_gene(genotype_matches[:brca].to_i)
              Maybe(genotype_matches[:variantclass]).map { |x| genotype.add_variant_class(x.to_i) }
              if extract_single_mutation(report_string, genotype)
              else
                @failed_report_parse_counter += 1
              end
              [genotype]
            end
          end

          # Extract from failed screenings
          class ScreeningFailed < GenotypePattern
            VALID_REGEX = /^(?:(?<method>ngs) )?screening failed$/i

            def extract(genotype_string, _report_string, genotype)
              self.class::VALID_REGEX.match(genotype_string)
              Maybe($LAST_MATCH_INFO[:method]).map { |x| genotype.add_method(x) }
              genotype.add_status(9)
              @report_parse_attempt_counter += 1
              # TODO: is it worth assigning a gene here?
              [genotype]
            end
          end

          # Extract from genotypes which are described as 'word report', and normal
          class WordReportNormal < GenotypePattern
            VALID_REGEX = /^word report - normal$/i

            def extract(_genotype_string, report_string, genotype)
              @report_parse_attempt_counter += 1
              @failed_report_parse_counter += 1 unless self.class::VALID_REGEX.match(report_string)
              # When both genotype and report have no information, not much you can do
              [genotype]
            end
          end

          # Extract from genotypes which are normal, but with failed MLPA
          class DoubleNormalMLPAFail < GenotypePattern
            VALID_REGEX = /^normal #{Import::CommonUtility::BRCA} and #Import::CommonUtility::BRCA, MLPA fail$/i
            SEQUENCE    = /screened for #{Import::CommonUtility::BRCA} and #{Import::CommonUtility::BRCA} mutations by sequence analysis/i
            MLPA        = /mlpa analysis of #{Import::CommonUtility::BRCA} failed/i

            def extract(_genotype_string, report_string, genotype)
              @report_parse_attempt_counter += 1
              if self.class::SEQUENCE.match(report_string)
                genotype.add_method('ngs') # TODO: is ngs a valid assumption for sequencing?
                genotype2 = genotype.dup
                genotype.add_gene(1)
                genotype.add_status(1)
                genotype2.add_gene(2)
                genotype2.add_status(1)
                if self.class::MLPA.match(report_string)
                  genotype3 = genotype.dup
                  genotype3.add_gene($LAST_MATCH_INFO[:brca])
                  genotype3.add_method('mlpa')
                  genotype3.add_status(9)
                  return [genotype, genotype2, genotype3]
                end
                @failed_report_parse_counter += 1
                return [genotype, genotype2]
              else
                @failed_report_parse_counter += 1
                [genotype]
              end

              # When both genotype and report have no information, not much you can do
              [genotype]
            end
          end

          # Extract from genotypes describing truncation or frameshift
          class TruncationOrFrameshift < GenotypePattern
            VALID_REGEX = /(ngs )?b(?:rca)?(1|2) truncating.frameshift/i
            IMPACT_REGEX = /(?<impact>frameshift|nonsense|missense)/i
            def extract(genotype_string, report_string, genotype)
              @report_parse_attempt_counter += 1
              genotype_matches = self.class::VALID_REGEX.match(genotype_string)
              genotype.add_method(genotype_matches[1])
              genotype.add_gene(genotype_matches[2].to_i)

              if extract_single_mutation(report_string, genotype)
                genotype.add_variant_impact($LAST_MATCH_INFO[:impact]) if IMPACT_REGEX.match(report_string)
              else
                @failed_report_parse_counter += 1
              end
              [genotype]
            end
          end

          # Orchestrate extracting as much information as possible from the 'genotype'
          # and 'report' fields in the Leeds data
          class GenotypeAndReportExtractor
            def initialize
              @genotype_extractors = [DoubleNormal,
                Predictive,
                Confirmation,
                VariantClass,
                VariantSeq,
                TruncationOrFrameshift,
                AJNegative,
                AJPositive,
                ScreeningFailed,
                WordReportNormal,
                DoubleNormalMLPAFail].map(&:new)
                @no_match = 0
                @total_records = 0
                @logger = Log.get_logger
                @rejected = []
              end

              def process(genotype_string, report_string, genotype)
                @total_records += 1
                # TODO: strictly, should check that only one pattern is ever matched,
                #  as do does not ensure consistent ordering...
                @genotype_extractors.each do |genotype_pattern|
                  if genotype_pattern.valid?(genotype_string)
                    return(genotype_pattern.extract(genotype_string, report_string, genotype))
                  end
                end
                @no_match += 1
                @rejected.append([genotype_string, report_string])
                [genotype]
                # @logger.debug "WARNING: genotype did not match any pattern: #{genotype_string}"
              end

              def summary
                @genotype_extractors.map(&:performance_summary)
                all_failed = @genotype_extractors.
                map(&:failed_report_parse_counter).
                inject(0) { |sum, x| sum + x }
                @logger.info "#{@no_match} of #{@total_records} records failed to match any genotype pattern"
                @logger.info "#{all_failed} records could only be parsed at genotype level"
                @logger.info 'Complete extraction successful on %0.2f percent of records' %
                [(@total_records.to_f - all_failed - @no_match) / @total_records * 100]
                reject_summary = @rejected.
                sort_by { |x| x[0] }.
                chunk { |x| x[0] }.
                map { |a, b| [a, b.size] }.
                sort_by { |x| x[1] }.
                reverse
                @logger.debug 'Unparseable genotypes:'
                reject_summary.each do |entry|
                  @logger.debug "\t#{entry[1]} #{entry[0]}"
                end
              end
      
          end
        end
      end
    end
  end
end
