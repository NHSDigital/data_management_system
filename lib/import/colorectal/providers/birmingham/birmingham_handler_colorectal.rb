require 'import/helpers/colorectal/providers/rq3/rq3_constants'
require 'import/helpers/colorectal/providers/rq3/rq3_helper'
module Import
  module Colorectal
    module Providers
      module Birmingham
        # Process Birmingham-specific record details into generalized internal genotype format
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
          end

          def process_genetictestscope(genocolorectal, record)
            Maybe(record.raw_fields['moleculartestingtype']).each do |tscope|
              if TEST_SCOPE_MAP_COLO_COLO[tscope.downcase.strip]
                genocolorectal.add_test_scope(TEST_SCOPE_MAP_COLO_COLO[tscope.downcase.strip])
              end
            end
          end

          def process_variants_from_report(genocolorectal, record)
            genotypes  = []
            posnegtest = record.raw_fields['overall2']
            testresult = record.raw_fields['teststatus']
            testreport = record.raw_fields['report']
            genelist   = COLORECTAL_GENES_MAP[record.raw_fields['indication']]
            return genotypes unless genelist

            if posnegtest.upcase == 'P'
              @logger.debug 'ABNORMAL TEST'
              if testresult.scan(/MYH/).size.positive?
                process_mutyh_specific_variants(testresult, genelist, genotypes,
                                                genocolorectal, record)
              elsif testresult.scan(COLORECTAL_GENES_REGEX).empty?
                if testreport.scan(CDNA_REGEX).size.positive?
                  process_testreport_cdna_variants(testreport, genelist, genotypes,
                                                   genocolorectal, record)
                elsif testreport.scan(CHR_VARIANTS_REGEX).size.positive?
                  process_chromosomal_variant(testreport, genelist, genotypes,
                                              record, genocolorectal)
                else
                  process_malformed_variants(testresult, testreport, genelist, genotypes,
                                             genocolorectal, record)
                end
              elsif testresult.scan(CDNA_REGEX).size.positive?
                process_testresult_cdna_variants(testresult, testreport, genelist,
                                                 genotypes, record, genocolorectal)
              elsif testresult.scan(CHR_VARIANTS_REGEX).size.positive?
                process_chr_variants(record, testreport, genotypes, genocolorectal)
              elsif testresult.match(/No known pathogenic/i)
                negativegenes = genelist
                process_negative_genes(negativegenes, genotypes, genocolorectal)
              else
                if full_screen?(record)
                  process_full_screen(record, testreport, genotypes, genocolorectal)
                end
                genocolorectal.add_gene_colorectal(testresult.scan(COLORECTAL_GENES_REGEX).join)
                genocolorectal.add_gene_location('')
                genocolorectal.add_status(2)
                genotypes.append(genocolorectal)
              end
            elsif posnegtest.upcase == 'N'
              process_negative_records(genelist, genotypes, testresult,
                                       testreport, record, genocolorectal)
            else
              @logger.debug "UNRECOGNISED TAG FOR #{record.raw_fields[indication]}"
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
