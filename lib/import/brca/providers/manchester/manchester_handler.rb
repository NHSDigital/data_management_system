require 'pry'
require 'possibly'

module Import
  module Brca
    module Providers
      module Manchester
        # Process Manchester-specific record details into generalized internal genotype format
        class ManchesterHandler < Import::Brca::Core::ProviderHandler
          PASS_THROUGH_FIELDS = %w[ age consultantcode
                                    receiveddate
                                    authoriseddate
                                    providercode
                                    servicereportidentifier
                                    collecteddate
                                    receiveddate
                                    age
                                    genotype ] .freeze
          DUAL_BRCA_REGEX = /^(?:brca(?<brca_a>1|2) )?
                             c.(?<cdna>[^ ]+)
                             (?: p.\((?<protein>[^\)]+)\))?
                             \s?
                             (?<zygosity>het)?
                             (?:, brca(?<brca_b>1|2)
                             \s(?<normal>normal))?.?$/ix .freeze
          DUAL_BRCA_NORMAL_REGEX = /^brca1 normal, brca2 normal$/i .freeze
          BRCA_REGEX = /(?<brca>BRCA[0-9])/i .freeze

          def initialize(batch)
            @failed_genotype_counter = 0
            @gene_counter = 0
            @failed_gene_counter = 0
            @chek_counter = 0
            @failed_gene_assignment_counter = 0
            super
          end

          def process_fields(record)
            @lines_processed += 1 # TODO: factor this out to be automatic across handlers
            genotype = Import::Brca::Core::GenotypeBrca.new(record)
            genotype.add_passthrough_fields(record.mapped_fields,
                                            record.raw_fields,
                                            PASS_THROUGH_FIELDS)
            # @persister.integrate_and_store(genotype)
            # genotype.add_test_scope(:full_screen)
            # genotype.add_molecular_testing_type_strict(:predictive)
            add_organisationcode_testresult(genotype)
            final_genotypes = process_raw_genotype(genotype, record)
            final_genotypes.map { |cur_genotype| @persister.integrate_and_store(cur_genotype) }
          end

          def add_organisationcode_testresult(genotype)
            genotype.attribute_map['organisationcode_testresult'] = '69820'
          end

          def process_raw_genotype(genotype, record)
            geno = record.mapped_fields['genotype']
            @logger.debug 'Gene field absent or non-BRCA for this record; cannot process' unless geno
            return if geno.nil?

            case geno
            when /^normal$/i, /^no shift$/i
              if BRCA_REGEX.match(record.raw_fields['exon'])
                # puts "#{$LAST_MATCH_INFO[:brca]}"
                genotype.add_gene($LAST_MATCH_INFO[:brca])
                genotype.add_status(:negative)
              end
              [genotype]
              # scour_for_gene(record.raw_fields['exon'], genotype)
            when DUAL_BRCA_NORMAL_REGEX
              genotype2 = genotype.dup
              genotype.add_status(:negative)
              genotype.add_gene(1)
              genotype2.add_gene(2)
              genotype2.add_status(:negative)
              [genotype, genotype2]
            when DUAL_BRCA_REGEX
              genotype2 = genotype.dup
              genotype.add_gene($LAST_MATCH_INFO[:brca_a]) unless $LAST_MATCH_INFO[:brca_a].nil?
              genotype.add_gene_location($LAST_MATCH_INFO[:cdna]) unless $LAST_MATCH_INFO[:cdna].nil?
              genotype.add_protein_impact($LAST_MATCH_INFO[:protein]) unless $LAST_MATCH_INFO[:protein].
                                                                             nil?
              genotype.add_status(:positive)
              genotype2.add_gene($LAST_MATCH_INFO[:brca_b]) unless $LAST_MATCH_INFO[:brca_b].nil?
              genotype2.add_status(:negative)
              [genotype, genotype2]
              # if $LAST_MATCH_INFO[:brca_a].nil? && $LAST_MATCH_INFO[:brca_b].nil?
              #   scour_for_gene(record.mapped_fields['exon'],genotype)
              # if $LAST_MATCH_INFO[:brca_a].nil?
              # @logger.error 'Genotype string insufficient to determine gene or search other fields'
              # @failed_gene_assignment_counter += 1
              # puts "I reached 4th "
              # [genotype]
              #         end
              # Do we want to set the status here? We don't actually know if it's higher risk
              # when /brca(?<gene>1|2) ex(?<ex1>\d+) to ex(?<ex2>\d+) (?<mod>del|dup) het$/i
              #    genotype.add_gene($LAST_MATCH_INFO[:gene])
              #    genotype.add_exon_location("#{$LAST_MATCH_INFO[:ex1]}-#{$LAST_MATCH_INFO[:ex2]}")
              #    genotype.add_variant_type($LAST_MATCH_INFO[:mod])
              #    [genotype]
              # when /^chek2.*$/i
              #     For now, throw these out, as it is not BRCA
              #     TODO: do try and record this
              #    @chek_counter += 1
              #    nil
            when /fail/i
              genotype.add_status(:failed)
              [genotype]
            else
              @logger.debug "FAILED genotype parse for: #{record.raw_fields['genotype']}"
              @failed_genotype_counter += 1
              [genotype]
            end
          end

          def summarize
            @logger.info '***************** Handler Report *******************'
            @logger.info "Num gene assignments failed: #{@failed_gene_assignment_counter} "\
                         "of #{@lines_processed} lines"
            @logger.info "Num genotypes failed to parse: #{@failed_genotype_counter}"\
                         "of #{@lines_processed} attempted"
            @logger.info "Num CHEK2: #{@chek_counter}"
          end

          # def extract_brca(genes)
          #   Array(genes).reject(&:nil?).map { |entry| entry.scan(BRCA_REGEX).
          #                                                   map { |match| match[0] } }.flatten
          # end
          #
          # # When the genotype doesn't specify BRCA1/2, search through other text fields to
          # # try to find a unique gene name
          # def scour_for_gene(record, genotype)
          #   brca_vals = extract_brca(record)
          #   if brca_vals.size == 1
          #     genotype.add_gene(brca_vals[0].to_i)
          #   elsif brca_vals.size > 1
          #     @logger.warn 'Too many gene names found, therefore none assigned'
          #     @failed_gene_assignment_counter += 1
          #   else
          #     @logger.debug 'No gene names found, therefore none assigned'
          #     @failed_gene_assignment_counter += 1
          #   end
          # end
        end
      end
    end
  end
end
