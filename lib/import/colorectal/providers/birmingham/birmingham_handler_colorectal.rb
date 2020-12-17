require 'possibly'
require 'import/storage_manager/persister'
require 'pry'
require 'import/brca/core/provider_handler'
require 'import/helpers/colorectal/providers/rq3/rq3_constants'

module Import
  module Colorectal
    module Providers
      module Birmingham
        # Process Cambridge-specific record details into generalized internal genotype format
        class BirminghamHandlerColorectal < Import::Brca::Core::ProviderHandler
          include Import::Helpers::Colorectal::Providers::Rq3::Rq3Constants

          def initialize(batch)
            @test_number = 0
            @failed_genocolorectal_counter = 0
            @successful_gene_counter = 0
            @failed_gene_counter = 0
            @negative_test = 0
            @positive_test = 0
            super
          end

          def process_fields(record)
            genocolorectal = Import::Colorectal::Core::Genocolorectal.new(record)
            genocolorectal.add_passthrough_fields(record.mapped_fields,
                                                  record.raw_fields,
                                                  PASS_THROUGH_FIELDS_COLO)
            process_genetictestscope(genocolorectal, record)
            res = process_variants_from_report(genocolorectal, record)
            res.each { |cur_genotype| @persister.integrate_and_store(cur_genotype) }
            # @persister.integrate_and_store(genocolorectal)
          end

          def process_genetictestscope(genocolorectal, record)
            Maybe(record.raw_fields['moleculartestingtype']).each do |tscope|
              if TEST_SCOPE_MAP_COLO_COLO[tscope.downcase.strip]
                genocolorectal.add_test_scope(TEST_SCOPE_MAP_COLO_COLO[tscope.downcase.strip])
                @logger.debug 'Processed genetictestscope '\
                              "#{TEST_SCOPE_MAP_COLO_COLO[tscope.downcase.strip]} for #{tscope}"
              else @logger.debug 'UNABLE to process genetictestscope'
              end
            end
          end

          def process_variants_from_report(genocolorectal, record)
            genotypes = []
            posnegtest = record.raw_fields['overall2']
            testresult = record.raw_fields['teststatus']
            testreport = record.raw_fields['report']
            #TO DO: WRITE FUNCTIONS FOR GENOTYPE LIST POPULATION AND REDUCE FUNCTIONS TO
            # NON-REDUNDANT METHODS
            if COLORECTAL_GENES_MAP[record.raw_fields['indication']]
              genelist = COLORECTAL_GENES_MAP[record.raw_fields['indication']]
              if posnegtest.upcase == 'P' # if there is an abnormal test
                @logger.debug 'ABNORMAL TEST'
                # @logger.debug 'ABNORMAL TEST FOUND'
                # if testresult.match(CDNA_REGEX)
                #   @logger.debug 'Found CDNA variant'
                #   if testresult.nil? || testresult.scan(COLORECTAL_GENES_REGEX).empty?
                #     @logger.debug 'TEST RESULTS EMPTY'
                #   elsif testreport.nil? || testreport.scan(COLORECTAL_GENES_REGEX).empty?
                #     @logger.debug 'TEST REPORT EMPTY'
                #   elsif !testresult.scan(COLORECTAL_GENES_REGEX).empty? && !testreport.scan(COLORECTAL_GENES_REGEX).empty? &&
                #     testresult.scan(COLORECTAL_GENES_REGEX).uniq.size != testreport.scan(COLORECTAL_GENES_REGEX).uniq.size
                #       @logger.debug 'INCONSISTENCY OF DECLARED GENES IN TESTRESULT AND TESTREPORT'
                #   elsif !testresult.scan(COLORECTAL_GENES_REGEX).empty? && !testreport.scan(COLORECTAL_GENES_REGEX).empty? &&
                #     testresult.scan(COLORECTAL_GENES_REGEX).uniq.size == testreport.scan(COLORECTAL_GENES_REGEX).uniq.size
                #     @logger.debug 'SAME NUMBER OF DECLARED GENES IN TESTRESULT AND TESTREPORT'
                #   end
                # elsif testresult.match(CHR_VARIANTS_REGEX)
                #   @logger.debug 'LARGE CHROMOSOMAL ABERRATION FOUND'
                # elsif testresult.match(CHR_VARIANTS_REGEX) && testresult.match(CDNA_REGEX)
                # else @logger.debug 'FOUND BOTH LARGE CHROMOSOMAL ABERRATION AND CDNA VARIANT'
                # end
              elsif posnegtest.upcase == 'N'
                @logger.debug 'NORMAL TEST FOUND'
                negativegenes = genelist
                process_negative_genes(negativegenes, genotypes, genocolorectal, record)
              end
            end
            genotypes
          end

          def process_negative_genes(negativegenes, genotypes, genocolorectal, record)
            negativegenes.each do |negativegene|
              dup_genocolorectal = genocolorectal.dup_colo
              @logger.debug "Found #{negativegene} for list #{negativegenes}"
              dup_genocolorectal.add_status(1)
              dup_genocolorectal.add_gene_colorectal(negativegene)
              dup_genocolorectal.add_protein_impact(nil)
              dup_genocolorectal.add_gene_location(nil)
              genotypes.append(dup_genocolorectal)
            end
          end
          
          
          def summarize
            @logger.info '***************** Handler Report *******************'
            @logger.info "Num genes failed to parse: #{@failed_gene_counter} of "\
            "#{@persister.genetic_tests.values.flatten.size} tests being attempted"
            @logger.info "Num genes successfully parsed: #{@successful_gene_counter} of"\
            "#{@persister.genetic_tests.values.flatten.size} attempted"
            @logger.info "Num genocolorectals failed to parse: #{@failed_genocolorectal_counter}"\
            "of #{@lines_processed} attempted"
            @logger.info "Num positive tests: #{@positive_test}"\
            "of #{@persister.genetic_tests.values.flatten.size} attempted"
            @logger.info "Num negative tests: #{@negative_test}"\
            "of #{@persister.genetic_tests.values.flatten.size} attempted"
          end
        end
      end
    end
  end
end
