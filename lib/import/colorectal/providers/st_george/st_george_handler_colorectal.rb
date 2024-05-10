require 'possibly'
require 'pry'
require 'Date'

module Import
  module Colorectal
    module Providers
      module StGeorge
        # Process St George-specific record details into generalized internal genotype format
        class StGeorgeHandlerColorectal < Import::Germline::ProviderHandler
          include Import::Helpers::Colorectal::Providers::Rj7::Constants

          def process_fields(record)
            genotype = Import::Colorectal::Core::Genocolorectal.new(record)

            
            # records using new importer should only have SRIs starting with V
            return unless record.raw_fields['servicereportidentifier'].start_with?('V')

            


            genotype.add_passthrough_fields(record.mapped_fields, record.raw_fields, PASS_THROUGH_FIELDS)
            

            assign_test_type(genotype, record)

          end 

          def assign_test_type(genotype, record)
            # extract molecular testing type from the raw record
            # map molecular testing type and assign to genotype using
            # add_molecular_testing_type method from genotype.rb

            return if record.raw_fields['moleculartestingtype'].blank?

            return unless TEST_TYPE_MAP[record.raw_fields['moleculartestingtype']]

            genotype.add_molecular_testing_type(TEST_TYPE_MAP[record.raw_fields['moleculartestingtype']])

          end




























        end
      end
    end
  end
end

