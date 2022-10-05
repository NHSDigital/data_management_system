require 'possibly'
require 'pry'

module Import
  module Brca
    module Providers
      module Birmingham
        # Process Birmingham-specific record details into generalized internal genotype format
        class BirminghamHandlerNewformat < Import::Germline::ProviderHandler
          include Import::Helpers::Brca::Providers::Rq3::Rq3Constants
          include Import::Helpers::Brca::Providers::Rq3::Rq3Helper

          def process_fields(record)
            genotype = Import::Brca::Core::GenotypeBrca.new(record)
            genotype.add_passthrough_fields(record.mapped_fields,
                                            record.raw_fields,
                                            PASS_THROUGH_FIELDS_BRCA)
            process_genetictestscope(genotype, record)
            add_organisationcode_testresult(genotype)
            variant_processor = VariantProcessor.new(genotype, record, @logger)
            res = variant_processor.process_variants_from_report
            res.each { |cur_genotype| @persister.integrate_and_store(cur_genotype) }
          end

          def summarize
            @logger.info '***************** Handler Report ******************'
            @logger.info "Num failed genotype parses: #{@failed_genotype_parse_counter}"\
                         "of #{@genotype_counter}"
            @logger.info "Total lines processed: #{@lines_processed}"
          end
        end
      end
    end
  end
end
