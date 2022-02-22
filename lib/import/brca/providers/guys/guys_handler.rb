require 'possibly'

module Import
  module Brca
    module Providers
      module Guys
        # Process Guys/St Thomas-specific record details into generalized internal genotype format
        class GuysHandler < Import::Brca::Core::ProviderHandler
          PASS_THROUGH_FIELDS = %w[age receiveddate sortdate requesteddate
                                   requesteddate
                                   servicereportidentifier
                                   consultantcode
                                   providercode] .freeze

          def process_fields(record)
            genotype = Import::Brca::Core::GenotypeBrca.new(record)
            @aj_report_date = record.raw_fields['ashkenazi assay report date']
            @aj_assay_result = record.raw_fields['ashkenazi assay result']
            @predictive_report_date = record.raw_fields['predictive report date']
            @brca1_mutation = record.raw_fields['brca1 mutation']
            @brca2_mutation = record.raw_fields['brca2 mutation']
            binding.pry
            genotype.add_passthrough_fields(record.mapped_fields,
                                            record.raw_fields,
                                            PASS_THROUGH_FIELDS)
            mtype = record.raw_fields['moleculartestingtype']
            genotype.add_molecular_testing_type_strict(mtype) if mtype
            add_organisationcode_testresult(genotype)
            @persister.integrate_and_store(genotype)
          end

          def add_organisationcode_testresult(genotype)
            genotype.attribute_map['organisationcode_testresult'] = '699L0'
          end

          # use the raw:predictive test performed overall, but check that full screen result is null
          #                                     but if predictive is yes and full screen is not null,
          #                                     consider it a full screen (non null 'full screen results'),
          #                                     and don't populate testtype
          # if yes => testingtype is predictive and testscope is targeted
          #            UNLESS either aj or either polish field are not null,
          #            in which case testscope is the corresponding term,
        end
      end
    end
  end
end
