require 'possibly'

module Import
  module Brca
    module Providers
      module Nottingham
        # Process Nottingham-specific record details into generalized internal genotype format
        class NottinghamHandler < Import::Germline::ProviderHandler
          include Import::Helpers::Brca::Providers::Rx1::Rx1Constants

          def process_fields(record)
            @lines_processed += 1
            genotype = Import::Brca::Core::GenotypeBrca.new(record)
            genotype.add_passthrough_fields(record.mapped_fields,
                                            record.raw_fields,
                                            PASS_THROUGH_FIELDS)
            add_moleculartestingtype(record, genotype)
            assign_test_scope(record, genotype)
            process_gene(genotype, record)
            process_cdna_or_exonic_variants(genotype, record)
            process_protein_impact(genotype, record)
            process_varpathclass(genotype, record)
            add_organisationcode_testresult(genotype)
            assign_test_status(record, genotype)
            @persister.integrate_and_store(genotype)
          end

          def add_organisationcode_testresult(genotype)
            genotype.attribute_map['organisationcode_testresult'] = '698A0'
          end

          def add_moleculartestingtype(record, genotype)
            testingtype = record.raw_fields['moleculartestingtype']
            genotype.add_molecular_testing_type_strict(TEST_TYPE_MAP[testingtype])
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

          def assign_test_status(record, genotype)
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

          def process_protein_impact(genotype, record)
            return if record.raw_fields['genotype'].nil?

            variantfield = record.raw_fields['genotype']
            genotype.add_protein_impact(variantfield.match(PROTEIN_REGEX)[:impact]) unless
            variantfield.match(PROTEIN_REGEX).nil?
          end

          def process_cdna_or_exonic_variants(genotype, record)
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
            gene = record.mapped_fields['gene']&.to_i
            genotype.add_gene(gene) unless gene.nil?
          end
        end
      end
    end
  end
end
