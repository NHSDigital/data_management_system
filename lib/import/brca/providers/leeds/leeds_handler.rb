require 'pry'

module Import
  module Brca
    module Providers
      module Leeds
        # Process Leeds-specific record details into generalized internal genotype format
        class LeedsHandler < Import::Germline::ProviderHandler
          TEST_SCOPE_MAP = { 'diagnostic' => :full_screen,
                             'mutation screening' => :full_screen,
                             'confirmation' => :targeted_mutation,
                             'predictive' => :targeted_mutation,
                             'prenatal' => :targeted_mutation,
                             'ashkenazi pre-screen' => :aj_screen,
                             '(v2) Any gene C5 - unaffected patient' => :full_screen,
                             '(v2) Class 5 low penetrance gene' => :full_screen,
                             '(v2) Normal' => :full_screen,
                             '(v2) Normal (MLPA dosage)' => :full_screen,
                             'B1/B2 - C3 pos' => :full_screen,
                             'B1/B2 Class 3 - UNAFFECTED' => :full_screen,
                             'B1/B2 Class 3 UV' => :full_screen,
                             'B1/B2 Class 4 UV' => :full_screen,
                             'B1/B2 Class 5 UV' => :full_screen,
                             'B2 Class 4 UV' => :full_screen,
                             'BRCA - Diagnostic Class 3' => :full_screen,
                             'BRCA - Diagnostic Class 4' => :full_screen,
                             'BRCA - Diagnostic Class 5' => :full_screen,
                             'BRCA - Diagnostic Class 5 - MLPA' => :full_screen,
                             'BRCA - Diagnostic Class 5 - UNAFFECTED' => :full_screen,
                             'BRCA - Diagnostic Normal' => :full_screen,
                             'BRCA - Diagnostic Normal - UNAFFECTED' => :full_screen,
                             'BRCA MS - Diag C3' => :full_screen,
                             'BRCA MS - Diag C4/5' => :full_screen,
                             'BRCA MS Diag Normal' => :full_screen,
                             'BRCA#/PALB2 - Diag Normal' => :full_screen,
                             'BRCA/PALB2 - Diag C4/5' => :full_screen,
                             'Conf B2 C4/C5 seq pos' => :targeted_mutation,
                             'Normal B1 and B2' => :full_screen,
                             'Normal B1/B2' => :full_screen,
                             'Normal B1/B2 - UNAFFECTED' => :full_screen,
                             'Pred B1 C4/C5 MLPA neg' => :targeted_mutation,
                             'Pred B1 C4/C5 MLPA pos' => :targeted_mutation,
                             'Pred B1 C4/C5 seq neg' => :targeted_mutation,
                             'Pred B1 C4/C5 seq pos' => :targeted_mutation,
                             'Pred B2 C4/C5 MLPA pos' => :targeted_mutation,
                             'Pred B2 C4/C5 seq neg' => :targeted_mutation,
                             'Pred B2 C4/C5 seq pos' => :targeted_mutation,
                             'Pred B2 MLPA neg' => :targeted_mutation,
                             'Predictive AJ neg 3seq' => :aj_screen,
                             'Predictive AJ pos 3seq' => :aj_screen,
                             'Predictive BRCA1 MLPA neg' => :targeted_mutation,
                             'Predictive BRCA1 seq pos' => :targeted_mutation,
                             'Predictive BRCA2 seq neg' => :targeted_mutation }.freeze

          TEST_TYPE_MAP = { 'diagnostic' => :diagnostic,
                            'mutation screening' => :diagnostic,
                            'confirmation' => :diagnostic,
                            'predictive' => :predictive,
                            'prenatal' => :prenatal,
                            'ashkenazi pre-screen' => nil,
                            '(v2) Any gene C5 - unaffected patient' => :predictive,
                            '(v2) Class 5 low penetrance gene' => :diagnostic,
                            '(v2) Normal' => :diagnostic,
                            '(v2) Normal (MLPA dosage)' => :diagnostic,
                            'B1/B2 - C3 pos' => :diagnostic,
                            'B1/B2 Class 3 - UNAFFECTED' => :predictive,
                            'B1/B2 Class 3 UV' => :diagnostic,
                            'B1/B2 Class 4 UV' => :diagnostic,
                            'B1/B2 Class 5 UV' => :diagnostic,
                            'B2 Class 4 UV' => :diagnostic,
                            'BRCA - Diagnostic Class 3' => :diagnostic,
                            'BRCA - Diagnostic Class 4' => :diagnostic,
                            'BRCA - Diagnostic Class 5' => :diagnostic,
                            'BRCA - Diagnostic Class 5 - MLPA' => :diagnostic,
                            'BRCA - Diagnostic Class 5 - UNAFFECTED' => :predictive,
                            'BRCA - Diagnostic Normal' => :diagnostic,
                            'BRCA - Diagnostic Normal - UNAFFECTED' => :predictive,
                            'BRCA MS - Diag C3' => :diagnostic,
                            'BRCA MS - Diag C4/5' => :diagnostic,
                            'BRCA MS Diag Normal' => :diagnostic,
                            'BRCA#/PALB2 - Diag Normal' => :diagnostic,
                            'BRCA/PALB2 - Diag C4/5' => :diagnostic,
                            'Conf B2 C4/C5 seq pos' => :diagnostic,
                            'Normal B1 and B2' => :diagnostic,
                            'Normal B1/B2' => :diagnostic,
                            'Normal B1/B2 - UNAFFECTED' => :predictive,
                            'Pred B1 C4/C5 MLPA neg' => :predictive,
                            'Pred B1 C4/C5 MLPA pos' => :predictive,
                            'Pred B1 C4/C5 seq neg' => :predictive,
                            'Pred B1 C4/C5 seq pos' => :predictive,
                            'Pred B2 C4/C5 MLPA pos' => :predictive,
                            'Pred B2 C4/C5 seq neg' => :predictive,
                            'Pred B2 C4/C5 seq pos' => :predictive,
                            'Pred B2 MLPA neg' => :predictive,
                            'Predictive AJ neg 3seq' => :predictive,
                            'Predictive AJ pos 3seq' => :predictive,
                            'Predictive BRCA1 MLPA neg' => :predictive,
                            'Predictive BRCA1 seq pos' => :predictive,
                            'Predictive BRCA2 seq neg' => :predictive }.freeze

          PASS_THROUGH_FIELDS = %w[age consultantcode
                                   providercode
                                   receiveddate
                                   authoriseddate
                                   requesteddate
                                   servicereportidentifier
                                   organisationcode_testresult
                                   specimentype].freeze
          FIELD_NAME_MAPPINGS = { 'consultantcode'  => 'practitionercode',
                                  'instigated_date' => 'requesteddate' }.freeze
          CDNA_REGEX = /c\.(?<cdna>[0-9]+.>[A-Za-z]+)|c\.(?<cdna>[0-9]+.[0-9]+[A-Za-z]+)/i.freeze
          PROTEIN_REGEX = /p\.\((?<impact>.\w+\d+\w+)\)/i.freeze
          BRCA1_REGEX = /B1/i.freeze
          BRCA2_REGEX = /B2/i.freeze
          TESTSTATUS_REGEX = /unaffected|neg|normal/i.freeze
          GENE_CDNA_PROTEIN_REGEX = /(?<brca> BRCA(1|2)) variant (c\.(?<cdna>[0-9]+.>[A-Za-z]+)|c\.(?<cdna>[0-9]+.[0-9]+[A-Za-z]+)) (?:p\.\((?<impact>.\w+\d+\w+)\))|(?<brca> BRCA(1|2)) sequence variant c\.(?<cdna>[0-9]+.>[A-Za-z]+)|c\.(?<cdna>[0-9]+.[0-9]+[A-Za-z]+) (?:p\.\((?<impact>.\w+\d+\w+)\))/i.freeze
          def initialize(batch)
            @extractor = ReportExtractor::GenotypeAndReportExtractor.new
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

            add_protein_impact_from_report(genotype, record) # Added by Francesco
            add_cdna_change_from_report(genotype, record) # Added by Francesco
            add_BRCA_from_raw_genotype(genotype, record) # Added by Francesco
            add_teststatus_from_raw_genotype(genotype, record) # Added by Francesco
            add_gene_cdna_protein_from_report(genotype, record) # Added by Francesco
            add_scope_and_type_from_genotype(genotype, record) # Added by Francesco
            add_b1_b2_c3_pos(genotype, record) # Added by Francesco ad hoc
            add_organisationcode_testresult(genotype)
            genotype.add_provider_name(record.raw_fields['reffac.name'])
            sample_type = record.raw_fields['sampletype']
            genotype.add_specimen_type(sample_type) unless sample_type.nil?
            mtype = record.raw_fields['moleculartestingtype']
            genotype.add_molecular_testing_type_strict(TEST_TYPE_MAP[mtype.downcase.strip]) unless mtype.
                                                                                                   nil?
            report = Maybe([record.raw_fields['report'],
                            record.mapped_fields['report'],
                            record.raw_fields['firstofreport']].
                             reject(&:nil?).first).or_else('') # la report_string
            geno = Maybe(record.raw_fields['genotype']).
                   or_else(Maybe(record.raw_fields['report_result']).
                   or_else(''))
            process_scope(geno, genotype, record)
            res = @extractor.process(geno, report, genotype)
            res.map { |cur_genotype| @persister.integrate_and_store(cur_genotype) }
          end

          def add_organisationcode_testresult(genotype)
            genotype.attribute_map['organisationcode_testresult'] = '699C0'
          end

          def add_BRCA_from_raw_genotype(genotype, record)
            case record.raw_fields['genotype']
            when BRCA1_REGEX
              genotype.add_gene('BRCA1')
            when BRCA2_REGEX
              genotype.add_gene('BRCA2')
            end
          end

          def add_teststatus_from_raw_genotype(genotype, record)
            case record.raw_fields['genotype']
            when TESTSTATUS_REGEX
              genotype.add_status('neg')
            else
              genotype.add_status('pos')
            end
          end

          def add_gene_cdna_protein_from_report(genotype, record)
            case record.mapped_fields['report']
            when GENE_CDNA_PROTEIN_REGEX
              genotype.add_gene($LAST_MATCH_INFO[:brca])
              genotype.add_gene_location($LAST_MATCH_INFO[:cdna])
              genotype.add_protein_impact($LAST_MATCH_INFO[:impact])
              @logger.debug 'SUCCESSFUL cdna change parse for: '\
                            "#{$LAST_MATCH_INFO[:brca]}, #{$LAST_MATCH_INFO[:cdna]},#{$LAST_MATCH_INFO[:impact]}"
            else
              @logger.debug 'FAILED gene,cdna,protein impact parse from report'
            end
          end

          def add_b1_b2_c3_pos(genotype, record)
            case record.raw_fields['genotype']
            when %r{B1/B2 - C3 pos}i
              genotype.add_test_scope(:full_screen)
              genotype.add_molecular_testing_type_strict(:diagnostic)
            end
          end

          def add_cdna_change_from_report(genotype, record)
            case record.mapped_fields['report']
            when CDNA_REGEX
              genotype.add_gene_location($LAST_MATCH_INFO[:cdna])
              @logger.debug "SUCCESSFUL cdna change parse for: #{$LAST_MATCH_INFO[:cdna]}"
            else
              @logger.debug 'FAILED cdna change parse for: '\
                            "#{record.mapped_fields['report']}"
            end
          end

          def add_protein_impact_from_report(genotype, record)
            case record.mapped_fields['report']
            when PROTEIN_REGEX
              genotype.add_protein_impact($LAST_MATCH_INFO[:impact])
              @logger.debug "SUCCESSFUL protein change parse for: #{$LAST_MATCH_INFO[:impact]}"
            else
              @logger.debug "FAILED protein change parse for: #{record.mapped_fields['report']}"
            end
          end

          def add_scope_and_type_from_genotype(genotype, record)
            Maybe(record.raw_fields['genotype']).each do |typescopegeno|
              genotype.add_molecular_testing_type_strict(TEST_TYPE_MAP[typescopegeno])
              scope = TEST_SCOPE_MAP[typescopegeno]
              genotype.add_test_scope(scope) if scope
            end
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
