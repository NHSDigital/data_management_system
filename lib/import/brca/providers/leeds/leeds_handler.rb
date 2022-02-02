require 'pry'

module Import
  module Brca
    module Providers
      module Leeds
        # Extract information from Leeds BRCA records
        class LeedsHandler < Import::Brca::Core::ProviderHandler
          include Import::Helpers::Brca::Providers::Rr8::Rr8Constants
          include Import::Helpers::Brca::Providers::Rr8::Rr8Helper
          include Import::Helpers::Brca::Providers::Rr8::Rr8ReportCases
          

          def initialize(batch)
            # @extractor = ReportExtractor::GenotypeAndReportExtractor.new
            @negative_test = 0 # Added by Francesco
            @positive_test = 0 # Added by Francesco
            super
          end

          def process_fields(record)
            genotype = Import::Brca::Core::GenotypeBrca.new(record)
            genotype.add_passthrough_fields(record.mapped_fields,
                                            record.raw_fields,
                                            PASS_THROUGH_FIELDS,
                                            FIELD_NAME_MAPPINGS)
            add_organisationcode_testresult(genotype)
            add_molecular_testing_type(record, genotype)
            variant_processor = VariantProcessor.new(genotype, record, @logger)
            variant_processor.assess_scope_from_genotype
            res = variant_processor.process_tests
            res.map { |cur_genotype| @persister.integrate_and_store(cur_genotype) }
          end

          def add_molecular_testing_type(record, genotype)
            return unless record.raw_fields['moleculartestingtype'].present?

            mtype = record.raw_fields['moleculartestingtype']
            genotype.add_molecular_testing_type_strict(TEST_TYPE_MAP[mtype.downcase.strip])
          end

          def add_organisationcode_testresult(genotype)
            genotype.attribute_map['organisationcode_testresult'] = '699C0'
          end
        end
      end
    end
  end
end
