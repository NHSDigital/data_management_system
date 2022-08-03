require 'possibly'

module Import
  module Brca
    module Providers
      module Nottingham
        # Process Nottingham-specific record details into generalized internal genotype format
        class NottinghamHandler < Import::Brca::Core::ProviderHandler
          # include ExtractionUtilities
          # TEST_TYPE_MAP = { 'confirmation' => :diagnostic,
          #                   'diagnostic' => :diagnostic,
          #                   'predictive' => :predictive,
          #                   'family studies' => :predictive,
          #                   'indirect' => :predictive } .freeze

          TEST_TYPE_MAP = { 'Carrier Screen' => '',
                            'Confirmation' => :diagnostic,
                            'Confirmation Of Familial Mutation' => :diagnostic,
                            'Confirmation of previous result' => :diagnostic,
                            'Diagnostic' => :diagnostic,
                            'Extract and Store' => '',
                            'Family Studies' => '',
                            'Indirect' => :predictive,
                            'Informativeness' => '',
                            'Mutation Screen' => '',
                            'Other' => '',
                            'Predictive' => :predictive,
                            'Store' => '',
                            'Variant Update' => '' }.freeze

          TEST_SCOPE_MAP = { 'Hereditary Breast and Ovarian Cancer (BRCA1/BRCA2)' => :full_screen,
                             'BRCA1 + BRCA2 + PALB2'                              => :full_screen,
                             'Breast Cancer Core Panel'                           => :full_screen,
                             'Breast Cancer Full Panel'                           => :full_screen,
                             'Breast Core Panel'                                  => :full_screen,
                             'BRCA1/BRCA2 PST'                                    => :targeted_mutation,
                             'Cancer PST'                                         => :targeted_mutation }.freeze

          TEST_STATUS_MAP = { '1: Clearly not pathogenic' => :negative,
                              '2: likely not pathogenic' => :negative,
                              '2: likely not pathogenic variant' => :negative,
                              'Class 2 Likely Neutral' => :negative,
                              'Class 2 likely neutral variant' => :negative,
                              '3: variant of unknown significance (VUS)' => :positive,
                              '4: likely pathogenic' => :positive,
                              '4:likely pathogenic' => :positive,
                              '4: Likely Pathogenic' => :positive,
                              '5: clearly pathogenic' => :positive,
                              'Mutation identified' => :positive }.freeze

          TEST_SCOPE_TTYPE_MAP = { 'Diagnostic' => :full_screen,
                                   'Indirect'   => :full_screen,
                                   'Predictive' => :targeted_mutation }.freeze

          PASS_THROUGH_FIELDS = %w[age authoriseddate
                                   receiveddate
                                   specimentype
                                   providercode
                                   consultantcode
                                   servicereportidentifier].freeze

          NEGATIVE_TEST = /Normal/i.freeze
          VARPATHCLASS_REGEX = /(?<varpathclass>[0-9](?=:))/.freeze
          # CDNA_REGEX = /c\.(?<cdna>[0-9]+[^\s|^, ]+)/i
          CDNA_REGEX = /c\.(?<cdna>.?[0-9]+[^\s|^, ]+)/i.freeze
          EXON_REGEX = /ex(?<ons>[a-z]+)?\s?(?<exons>[0-9]+(?<otherexons>-[0-9]+)?)\s
                        (?<vartype>del|dup)|(?<vartype>del[a-z]+|dup[a-z]+)(\sof)?\sexon(s)?\s
                        (?<exons>[0-9]+(?<otherexons>-[0-9]+)?)/xi.freeze
          PROTEIN_REGEX = /p\..(?<impact>.+)\)/i.freeze

          def initialize(batch)
            @failed_genotype_parse_counter = 0
            @genotype_counter = 0
            # @ex = LocationExtractor.new
            super
          end

          def process_fields(record)
            @lines_processed += 1
            genotype = Import::Brca::Core::GenotypeBrca.new(record)
            genotype.add_passthrough_fields(record.mapped_fields,
                                            record.raw_fields,
                                            PASS_THROUGH_FIELDS)
            add_moleculartestingtype(record, genotype)
            add_receiveddate(record, genotype)
            assign_test_scope(record, genotype)
            process_gene(genotype, record) # Added by Francesco
            process_cdna_change(genotype, record)
            process_protein_impact(genotype, record)
            process_varpathclass(genotype, record)
            add_organisationcode_testresult(genotype)
            assign_test_status(record, genotype) # added by Francesco
            @persister.integrate_and_store(genotype)
          end

          def add_organisationcode_testresult(genotype)
            genotype.attribute_map['organisationcode_testresult'] = '698A0'
          end

          def add_moleculartestingtype(record, genotype)
            testingtype = record.raw_fields['moleculartestingtype']
            genotype.add_molecular_testing_type_strict(TEST_TYPE_MAP[testingtype])
          end

          def add_receiveddate(record, genotype)
            received_date = record.raw_fields['sample received in lab date']
            genotype.add_received_date(received_date.downcase) unless received_date.nil?
          end

          def assign_test_scope(record, genotype)
            testscopefield = record.raw_fields['disease']
            testtypefield = record.raw_fields['moleculartestingtype']
            if TEST_SCOPE_MAP[testscopefield].present?
              genotype.add_test_scope(TEST_SCOPE_MAP[testscopefield])
            elsif %w[PALB2 CDH1 TP53].include? testscopefield
              genotype.add_test_scope(TEST_SCOPE_TTYPE_MAP[testtypefield])
            end
          end

          def normaltest_nullvariantfield?(record, teststatusfield, variantfield)
            return false if record.raw_fields['teststatus'].nil?

            teststatusfield == 'Normal' && variantfield.nil?
          end

          def normaltest_controlvariantfield?(record, teststatusfield, variantfield)
            return false if record.raw_fields['teststatus'].nil? &&
                            record.raw_fields['genotype'].nil?

            teststatusfield == 'Normal' && variantfield.scan(/normal|control/i).size.positive?
          end

          def normaltest_cdnavariantpositive?(record, teststatusfield, variantfield)
            return false if record.raw_fields['teststatus'].nil? &&
                            record.raw_fields['genotype'].nil?

            teststatusfield == 'Normal' && variantfield.scan(CDNA_REGEX).size.positive?
          end

          def normaltest_cnvvariantpositive?(record, teststatusfield, variantfield)
            return false if record.raw_fields['teststatus'].nil? &&
                            record.raw_fields['genotype'].nil?

            teststatusfield == 'Normal' && variantfield.scan(/del|dup/i).size.positive?
          end

          def completedtest_nullvariantfield?(record, teststatusfield, variantfield)
            return false if record.raw_fields['teststatus'].nil?

            teststatusfield == 'Completed' && variantfield.nil?
          end

          def completedtest_cdnavariantpositive?(record, teststatusfield, variantfield)
            return false if record.raw_fields['teststatus'].nil? &&
                            record.raw_fields['genotype'].nil?

            teststatusfield == 'Completed' && variantfield.scan(CDNA_REGEX).size.positive?
          end

          def nil_variantfield_teststatusfield?(_record, teststatusfield, variantfield)
            return false if teststatusfield.present? || variantfield.present?

            teststatusfield.nil? && variantfield.nil?
          end

          def assign_conditional_teststatus(record, teststatusfield, variantfield, genotype)
            if normaltest_nullvariantfield?(record, teststatusfield, variantfield) ||
               normaltest_controlvariantfield?(record, teststatusfield, variantfield) ||
               completedtest_nullvariantfield?(record, teststatusfield, variantfield)
              genotype.add_status(:negative)
            elsif normaltest_cdnavariantpositive?(record, teststatusfield, variantfield) ||
                  completedtest_cdnavariantpositive?(record, teststatusfield, variantfield) ||
                  normaltest_cnvvariantpositive?(record, teststatusfield, variantfield)
              genotype.add_status(:positive)
            end
          end

          def assign_test_status(record, genotype)
            teststatusfield = record.raw_fields['teststatus']
            variantfield = record.raw_fields['genotype']

            if TEST_STATUS_MAP[teststatusfield].present?
              binding.pry
              genotype.add_status(TEST_STATUS_MAP[teststatusfield])
            elsif nil_variantfield_teststatusfield?(record, teststatusfield, variantfield)
              genotype.add_status(4)
            else
              assign_conditional_teststatus(record, teststatusfield, variantfield, genotype)
            end
          end

          #
          # CONDITIONAL_TESTSTATUS_MAP = [
          #   %i[normaltest_nullvariantfield? add_negative_genotype],
          #   %i[normaltest_controlvariantfield? add_negative_genotype],
          #   %i[completedtest_nullvariantfield? add_negative_genotype],
          #   %i[normaltest_cdnavariantpositive? add_positive_genotype],
          #   %i[normaltest_cnvvariantpositive? add_positive_genotype],
          #   %i[completedtest_cdnavariantpositive? add_positive_genotype]
          # ].freeze
          #
          # def process_condtional_teststatus(record, teststatusfield, variantfield)
          #   params = {param1: record, param2: teststatusfield, param3: variantfield}
          #
          #   CONDITIONAL_TESTSTATUS_MAP.each do |condition, extraction|
          #     send(extraction) if send(condition*params)
          #   end
          # end
          #
          # def add_negative_genotype(genotype)
          #   genotype.add_status(:negative)
          # end
          #
          # def add_positive_genotype(genotype)
          #   genotype.add_status(:positive)
          # end

          def process_protein_impact(genotype, record)
            return if record.raw_fields['genotype'].nil?

            variantfield = record.raw_fields['genotype']
            genotype.add_protein_impact(variantfield.match(PROTEIN_REGEX)[:impact]) unless
            variantfield.match(PROTEIN_REGEX).nil?
            # end
          end

          def process_cdna_change(genotype, record)
            return if record.raw_fields['genotype'].nil?

            variantfield = record.raw_fields['genotype']

            if variantfield.scan(CDNA_REGEX).size.positive?
              genotype.add_gene_location(variantfield.match(CDNA_REGEX)[:cdna])
            elsif variantfield.scan(EXON_REGEX).size.positive?
              genotype.add_variant_type(variantfield.match(EXON_REGEX)[:vartype])
              genotype.add_exon_location(variantfield.match(EXON_REGEX)[:exons])
            end
          end

          def process_varpathclass(genotype, record)
            case record.raw_fields['teststatus']
            when VARPATHCLASS_REGEX
              genotype.add_variant_class($LAST_MATCH_INFO[:varpathclass].to_i)
            end
          end

          def process_gene(genotype, record)
            gene = record.mapped_fields['gene'].to_i
            genotype.add_gene(gene) unless gene.nil?
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
