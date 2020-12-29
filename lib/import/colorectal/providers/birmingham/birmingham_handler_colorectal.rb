require 'possibly'
require 'import/storage_manager/persister'
require 'pry'
require 'import/brca/core/provider_handler'
require 'import/helpers/colorectal/providers/rq3/rq3_constants'
require 'import/helpers/colorectal/providers/rq3/rq3_helper'
module Import
  module Colorectal
    module Providers
      module Birmingham
        # Process Cambridge-specific record details into generalized internal genotype format
        class BirminghamHandlerColorectal < Import::Brca::Core::ProviderHandler
          include Import::Helpers::Colorectal::Providers::Rq3::Rq3Constants
          include Import::Helpers::Colorectal::Providers::Rq3::Rq3Helper

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
                # @logger.debug 'Processed genetictestscope '\
                              # "#{TEST_SCOPE_MAP_COLO_COLO[tscope.downcase.strip]} for #{tscope}"
               else #@logger.debug 'UNABLE to process genetictestscope'
              end
            end
          end

          def process_variants_from_report(genocolorectal, record)
            genotypes = []
            posnegtest = record.raw_fields['overall2']
            testresult = record.raw_fields['teststatus']
            testreport = record.raw_fields['report']
            if COLORECTAL_GENES_MAP[record.raw_fields['indication']]
              genelist = COLORECTAL_GENES_MAP[record.raw_fields['indication']]
              if posnegtest.upcase == 'P'
                @logger.debug 'ABNORMAL TEST'
                if testresult.scan(/MYH/).size > 0
                  process_mutyh_specific_variants(testresult, genelist, genotypes, genocolorectal, record)
                elsif testresult.scan(COLORECTAL_GENES_REGEX).empty?
                  if testreport.scan(CDNA_REGEX).size > 0
                    process_testreport_cdna_variants(testreport, genelist, genotypes, genocolorectal, record)
                  elsif testreport.scan(CHR_VARIANTS_REGEX).size > 1
                    process_testreport_chromosome_variants(testreport, genelist, genotypes, genocolorectal, record)
                  else
                    process_malformed_variants(testresult, testreport, genelist, genotypes, genocolorectal, record)
                  end
                  genotypes
                else
                  if testresult.scan(CDNA_REGEX).size > 0
                    process_testresult_cdna_variants(testresult, genelist, genotypes, record, genocolorectal)
                  elsif testresult.scan(CHR_VARIANTS_REGEX).size > 0
                    process_testresult_chromosomal_variants(testresult, genelist, genotypes, record, genocolorectal)
                  elsif testresult.match(/No known pathogenic/i)
                    negativegenes = genelist
                    process_negative_genes(negativegenes, genotypes, genocolorectal, record)
                  else
                    negativegenes = genelist - testresult.scan(COLORECTAL_GENES_REGEX).flatten
                    process_negative_genes(negativegenes, genotypes, genocolorectal, record)
                    genocolorectal.add_gene_colorectal(testresult.scan(COLORECTAL_GENES_REGEX).join())
                    genocolorectal.add_gene_location('.')
                    genocolorectal.add_status(2)
                    genotypes.append(genocolorectal)
                  end
                  genotypes
                end
              elsif posnegtest.upcase == 'N'
                @logger.debug 'NORMAL TEST FOUND'
                negativegenes = genelist # + all the genes listed in the teststatus column
                process_negative_genes(negativegenes, genotypes, genocolorectal, record)
              end
            # else @logger.debug "UNRECOGNISED TAG FOR #{record.raw_fields[indication]}"
            end
            genotypes
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
