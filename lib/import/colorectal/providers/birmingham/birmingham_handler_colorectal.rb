
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
            add_organisationcode_testresult(genocolorectal)
            variant_processor = VariantProcessor.new(genocolorectal, record, @logger)
            res = variant_processor.process_variants_from_report
            res.each { |cur_genotype| @persister.integrate_and_store(cur_genotype) }
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
