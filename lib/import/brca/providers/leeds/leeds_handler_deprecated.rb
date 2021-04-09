# require 'providers/leeds/report_extractor'
require 'pry'

module Import
  module Brca
    module Providers
      module Leeds
        # Process Leeds-specific record details into generalized internal genotype format
        class LeedsHandlerDeprecated < Import::Brca::Core::ProviderHandler
          TEST_SCOPE_MAP = { 'diagnostic'           => :full_screen,
                             'mutation screening'   => :full_screen,
                             'confirmation'         => :targeted_mutation,
                             'predictive'           => :targeted_mutation,
                             'prenatal'             => :targeted_mutation,
                             'ashkenazi pre-screen' => :aj_screen }.freeze
          TEST_TYPE_MAP = { 'diagnostic'           => :diagnostic,
                            'mutation screening'   => :diagnostic,
                            'confirmation'         => :diagnostic,
                            'predictive'           => :predictive,
                            'prenatal'             => :prenatal,
                            'ashkenazi pre-screen' => nil }.freeze
          PASS_THROUGH_FIELDS = %w[age consultantcode
                                   providercode
                                   receiveddate
                                   authoriseddate
                                   requesteddate
                                   servicereportidentifier
                                   organisationcode_testresult
                                   specimentype] .freeze
          FIELD_NAME_MAPPINGS = { 'consultantcode'  => 'practitionercode',
                                  'instigated_date' => 'requesteddate' } .freeze
          def initialize(batch)
            @extractor = GenotypeAndReportExtractor.new
            @negative_test = 0 # Added by Francesco
            @positive_test = 0 # Added by Francesco
            super
          end

          def process_fields(record)
            genotype = Import::Brca::Core::Genotype.new(record)
            genotype.add_passthrough_fields(record.mapped_fields, record.raw_fields,
                                            PASS_THROUGH_FIELDS,
                                            FIELD_NAME_MAPPINGS)
            genotype.add_provider_name(record.raw_fields['reffac.name'])
            sample_type = record.raw_fields['sampletype']
            genotype.add_specimen_type(sample_type) unless sample_type.nil?
            mtype = record.raw_fields['moleculartestingtype']
            genotype.add_molecular_testing_type_strict(TEST_TYPE_MAP[mtype.downcase.strip]) unless mtype.nil?
            report = Maybe([record.raw_fields['report'], record.mapped_fields['report'],
                            record.raw_fields['firstofreport']].
                            reject(&:nil?).
                            first).
                     or_else('')
            geno = Maybe(record.raw_fields['genotype']).
                   or_else(Maybe(record.raw_fields['report_result']).
                   or_else(''))
            process_scope(geno, genotype, record)
            res = @extractor.process(geno, report, genotype)
            res.map { |cur_genotype| @persister.integrate_and_store(cur_genotype) }
          end

          def process_scope(geno, genotype, record)
            scope = Maybe(record.raw_fields['reason']).
                    or_else(Maybe(record.mapped_fields['genetictestscope']).or_else(''))
            # ------------ Set the test scope ---------------------
            if (geno.downcase.include? 'ashkenazi') || (geno.include? 'AJ')
              genotype.add_test_scope(:aj_screen)
            else
              stripped_scope = TEST_SCOPE_MAP[scope.downcase.strip]
              genotype.add_test_scope(stripped_scope) if stripped_scope
            end
          end

          def finalize
            @extractor.summary
            super
          end
        end
      end
    end
  end
end
