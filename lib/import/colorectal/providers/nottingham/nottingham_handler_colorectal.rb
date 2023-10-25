require 'possibly'

module Import
  module Colorectal
    module Providers
      module Nottingham
        # Process Nottingham-specific record details into generalized internal genotype format
        class NottinghamHandlerColorectal < Import::Germline::ProviderHandler
          include Import::Helpers::Colorectal::Providers::Rx1::Constants

          def initialize(batch)
            @failed_genotype_parse_counter = 0
            @genotype_counter = 0
            super
          end

          def process_fields(record)
            @lines_processed += 1
            genotype = Import::Colorectal::Core::Genocolorectal.new(record)
            genotype.add_passthrough_fields(record.mapped_fields,
                                            record.raw_fields,
                                            PASS_THROUGH_FIELDS_COLO)
            add_test_type(genotype, record)
            add_scope(genotype, record)
            add_variant(genotype, record)
            add_protein_impact(genotype, record)
            process_gene_colorectal(genotype, record) # Added by Francesco
            extract_variantclass_from_genotype(genotype, record) # Added by Francesco
            extract_teststatus(genotype, record) # added by Francesco
            add_organisationcode_testresult(genotype)
            @persister.integrate_and_store(genotype)
          end

          def add_organisationcode_testresult(genotype)
            genotype.attribute_map['organisationcode_testresult'] = '698A0'
          end

          def add_test_type(genotype, record)
            testingtype = record.raw_fields['moleculartestingtype'].downcase
            genotype.add_molecular_testing_type_strict(TEST_TYPE_MAP_COLO[testingtype.strip])
          end

          def add_scope(genotype, record)
            Maybe(record.raw_fields['disease']).each do |disease|
              case disease.downcase.strip
              when 'bowel cancer panel', 'hereditary non-polyposis colorectal cancer'
                genotype.add_test_scope(:full_screen)
              when 'hnpcc pst'
                genotype.add_test_scope(:targeted_mutation)
              else
                genotype.add_test_scope(:no_genetictestscope)
              end
            end
          end

          def add_variant(genotype, record)
            geno = record.raw_fields['genotype']
            case geno
            when CDNA_REGEX
              genotype.add_gene_location($LAST_MATCH_INFO[:cdna])
            when ADHOC_CDNA_REGEX
              genotype.add_gene_location($LAST_MATCH_INFO[:cdna])
            when SPACE_CDNA_REGEX
              genotype.add_gene_location($LAST_MATCH_INFO[:cdna])
            else
              @logger.debug 'UNSUCCESSFUL CDNA CHANGE PARSE'
            end
          end

          def add_protein_impact(genotype, record)
            protein = record.raw_fields['genotype']
            case protein
            when PROTEIN_IMPACT_REGEX
              genotype.add_protein_impact($LAST_MATCH_INFO[:impact])
            else
              @logger.debug 'UNSUCCESSFUL PROTEIN CHANGE PARSE'
            end
          end

          def normaltest_nullvariantfield?(teststatusfield, variantfield)
            return false if teststatusfield.nil?

            teststatusfield == 'Normal' && variantfield.blank?
          end

          def normaltest_controlvariantfield?(teststatusfield, variantfield)
            return false if teststatusfield.nil? && variantfield.nil?

            teststatusfield == 'Normal' && variantfield.scan(/normal|control/i).size.positive?
          end

          def normaltest_cdnavariantpositive?(teststatusfield, variantfield)
            return false if teststatusfield.nil? && variantfield.nil?

            teststatusfield == 'Normal' && variantfield.scan(CDNA_REGEX).size.positive?
          end

          def normaltest_cnvvariantpositive?(teststatusfield, variantfield)
            return false if teststatusfield.nil? && variantfield.nil?

            teststatusfield == 'Normal' && variantfield.scan(/del|dup/i).size.positive?
          end

          def completedtest_nullvariantfield?(teststatusfield, variantfield)
            return false if teststatusfield.nil?

            teststatusfield == 'Completed' && variantfield.blank?
          end

          def completedtest_cdnavariantpositive?(teststatusfield, variantfield)
            return false if teststatusfield.nil? && variantfield.nil?

            teststatusfield == 'Completed' && variantfield.scan(CDNA_REGEX).size.positive?
          end

          def nil_variantfield_teststatusfield?(teststatusfield, variantfield)
            return false if teststatusfield.present? || variantfield.present?

            teststatusfield.nil? && variantfield.nil?
          end

          def assign_conditional_teststatus(teststatusfield, variantfield, genotype)
            if normaltest_nullvariantfield?(teststatusfield, variantfield) ||
               normaltest_controlvariantfield?(teststatusfield, variantfield) ||
               completedtest_nullvariantfield?(teststatusfield, variantfield)
              genotype.add_status(:negative)
            elsif normaltest_cdnavariantpositive?(teststatusfield, variantfield) ||
                  completedtest_cdnavariantpositive?(teststatusfield, variantfield) ||
                  normaltest_cnvvariantpositive?(teststatusfield, variantfield)
              genotype.add_status(:positive)
            end
          end

          def extract_teststatus(genotype, record)
            teststatusfield = record.raw_fields['teststatus']
            variantfield = record.raw_fields['genotype']

            if TEST_STATUS_MAP[teststatusfield].present?
              genotype.add_status(TEST_STATUS_MAP[teststatusfield])
            elsif nil_variantfield_teststatusfield?(teststatusfield, variantfield)
              genotype.add_status(4)
            else
              assign_conditional_teststatus(teststatusfield, variantfield, genotype)
            end
          end

          def extract_variantclass_from_genotype(genotype, record)
            varpathclass_field = record.raw_fields['teststatus'].to_s.downcase
            case varpathclass_field
            when VARPATHCLASS_REGEX
              genotype.add_variant_class($LAST_MATCH_INFO[:varpathclass]&.to_i)
              @logger.debug "SUCCESSFUL VARPATHCLASS parse for: #{$LAST_MATCH_INFO[:varpathclass]}"
            when 'VUS'
              genotype.add_variant_class(3)
            else
              @logger.debug "FAILED VARPATHCLASS parse for: #{record.raw_fields['teststatus']}"
            end
          end

          def process_gene_colorectal(genotype, record)
            colorectal_input = record.raw_fields['gene']
            case colorectal_input
            when COLORECTAL_GENES_REGEX
              genotype.add_gene_colorectal(colorectal_input)
              @logger.debug "SUCCESSFUL COLORECTAL gene parse for: #{record.raw_fields['gene']}"
            else
              @logger.debug "FAILED COLORECTAL gene parse for: #{record.raw_fields['gene']}"
            end
          end

          def summarize
            @logger.info '***************** Handler Report ******************'
            @logger.info "Num failed genotype parses: #{@failed_genotype_parse_counter}"\
            'of #{@genotype_counter}'
            @logger.info "Total lines processed: #{@lines_processed}"
          end
        end
      end
    end
  end
end
