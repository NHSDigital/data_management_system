require 'possibly'

module Import
  module Brca
    module Providers
      module Guys
        # Process Guys/St Thomas-specific record details into generalized internal genotype format
        class GuysHandler < Import::Germline::ProviderHandler
          include Import::Helpers::Brca::Providers::Rj1::Rj1Constants
          include Import::Helpers::Brca::Providers::Rj1::Rj1TestsProcessor
          include Import::Helpers::Brca::Providers::Rj1::Rj1AshkenaziTestProcessor
          include Import::Helpers::Brca::Providers::Rj1::Rj1TargetedTestProcessor
          include Import::Helpers::Brca::Providers::Rj1::Rj1FullscreenTestProcessor
          include Import::Helpers::Brca::Providers::Rj1::Rj1PolishTestProcessor
          include Import::Helpers::Brca::Providers::Rj1::Rj1CommonMethodsProcessor

          PASS_THROUGH_FIELDS = %w[age receiveddate sortdate requesteddate
                                   requesteddate
                                   servicereportidentifier
                                   consultantcode
                                   providercode].freeze

          # rubocop:disable Metrics/AbcSize
          # rubocop:disable Metrics/MethodLength
          def process_fields(record)
            genotype = Import::Brca::Core::GenotypeBrca.new(record)
            genotype.add_passthrough_fields(record.mapped_fields,
                                            record.raw_fields,
                                            PASS_THROUGH_FIELDS)
            @genotype   = genotype
            @record     = record
            @genotypes  = []
            @aj_report_date = record.raw_fields['ashkenazi assay report date']
            @aj_assay_result = record.raw_fields['ashkenazi assay result']
            @predictive_report_date = record.raw_fields['predictive report date']
            @brca1_mutation = record.raw_fields['brca1 mutation']
            @brca2_mutation = record.raw_fields['brca2 mutation']
            @polish_report_date = record.raw_fields['polish assay report date']
            @polish_assay_result = record.raw_fields['polish assay result']
            @predictive_report_date = record.raw_fields['predictive report date']
            @authoriseddate = record.raw_fields['authoriseddate']
            @predictive = record.raw_fields['predictive']
            @ngs_result = record.raw_fields['ngs result']
            @ngs_report_date = record.raw_fields['ngs report date']
            @fullscreen_result = record.raw_fields['full screen result']
            @brca1_mlpa_result = record.raw_fields['brca1 mlpa results']
            @brca2_mlpa_result = record.raw_fields['brca2 mlpa results']
            @brca1_seq_result = record.raw_fields['brca1 seq result']
            @brca2_seq_result = record.raw_fields['brca2 seq result']
            @date_2_3_reported = record.raw_fields['date 2/3 reported']
            @brca1_report_date = record.raw_fields['full brca1 report date']
            @brca2_report_date = record.raw_fields['full brca2 report date']
            @brca2_ptt_report_date = record.raw_fields['brca2 ptt report date']
            @full_ppt_report_date = record.raw_fields['full ptt report date']

            mtype = record.raw_fields['moleculartestingtype']
            genotype.add_molecular_testing_type_strict(mtype) if mtype
            add_organisationcode_testresult(genotype)
            # Below method appends extracted items to @genotypes list
            process_tests
            @genotypes.flatten.each do |cur_genotype|
              @persister.integrate_and_store(cur_genotype)
            end
          end
          # rubocop:enable Metrics/AbcSize
          # rubocop:enable Metrics/MethodLength

          def add_organisationcode_testresult(genotype)
            genotype.attribute_map['organisationcode_testresult'] = '699L0'
          end

          def process_tests
            METHODS_MAP.each do |condition_extraction|
              condition, extraction = *condition_extraction
              send(extraction) if send(condition)
            end
          end
        end
      end
    end
  end
end
