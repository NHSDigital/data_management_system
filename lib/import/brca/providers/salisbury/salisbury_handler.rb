require 'possibly'

module Import
  module Brca
    module Providers
      module Salisbury
        # Process Salisbury-specific record details into generalized internal genotype format
        class SalisburyHandler < Import::Brca::Core::ProviderHandler
          include Import::Helpers::Brca::Providers::Rnz::RnzConstants

          def process_fields(record)
            return if record.raw_fields['moleculartestingtype'] == 'Lynch syndrome 3 gene panel'

            genotype = Import::Brca::Core::GenotypeBrca.new(record)
            genotype.add_passthrough_fields(record.mapped_fields,
                                            record.raw_fields,
                                            PASS_THROUGH_FIELDS)
            mol_testing_type = record.raw_fields['moleculartestingtype']&.downcase
            process_molecular_testing(genotype, mol_testing_type)
            add_organisationcode_testresult(genotype)
            extract_teststatus(genotype, record)
            res = process_variant_record(genotype, record)
            res.each { |cur_genotype| @persister.integrate_and_store(cur_genotype) }
          end

          def process_molecular_testing(genotype, mol_testing_type)
            genotype.add_molecular_testing_type_strict(TEST_TYPE_MAPPING[mol_testing_type])
            scope = TEST_SCOPE_MAPPING[mol_testing_type]
            if scope
              genotype.add_test_scope(scope)
            else
              genotype.add_test_scope(:no_genetictestscope)
            end
          end

          def add_organisationcode_testresult(genotype)
            genotype.attribute_map['organisationcode_testresult'] = '699H0'
          end

          def process_variant_record(genotype, record)
            genotypes = []
            variant = record.raw_fields['genotype']
            test_str = record.raw_fields['test']
            gene = extract_gene(test_str, variant, record)
            genotype.add_gene(gene[0])

            process_variants(genotype, variant) if positive_rec?(genotype) && variant.present?

            unless test_str.scan(CONFIRMATION_SEQ_NGS_CASE).size.positive? && gene.blank?
              genotypes.append(genotype)
            end

            if test_str.scan(CONFIRMATION_SEQ_NGS_CASE).size.positive?
              add_fs_negative_gene(gene, genotype, genotypes)
            end

            genotypes
          end

          def process_variants(genotype, variant)
            process_cdna_variant(genotype, variant)
            process_exonic_variant(genotype, variant)
            process_protein_impact(genotype, variant)
          end

          def process_exonic_variant(genotype, variant)
            return unless variant.scan(EXON_VARIANT_REGEX).size.positive?

            genotype.add_exon_location($LAST_MATCH_INFO[:exons])
            genotype.add_variant_type($LAST_MATCH_INFO[:mutationtype]&.downcase)
            @logger.debug "SUCCESSFUL exon variant parse for: #{variant}"
          end

          def process_cdna_variant(genotype, variant)
            return unless variant.scan(CDNA_REGEX).size.positive?

            genotype.add_gene_location($LAST_MATCH_INFO[:cdna])
            @logger.debug "SUCCESSFUL cdna change parse for: #{$LAST_MATCH_INFO[:cdna]}"
          end

          def process_protein_impact(genotype, variant)
            return unless variant.scan(PROTEIN_REGEX).size.positive?

            genotype.add_protein_impact($LAST_MATCH_INFO[:impact])
            @logger.debug "SUCCESSFUL protein parse for: #{$LAST_MATCH_INFO[:impact]}"
          end

          def add_fs_negative_gene(pos_gene, genotype, genotypes)
            negative_genes = %w[BRCA1 BRCA2] - pos_gene
            negative_genes&.each do |brca_gene|
              genotype_dup = genotype.dup
              genotype_dup.add_gene(brca_gene)
              genotype.add_status(:negative)
              genotypes.append(genotype_dup)
            end
          end

          def positive_rec?(genotype)
            genotype.attribute_map['teststatus'] == 2
          end

          # rubocop:disable Metrics/MethodLength, Metrics/CyclomaticComplexity
          def extract_gene(test_string, geno_str, record)
            positive_gene = []
            positive_gene << 'BRCA1' if record.raw_fields['servicereportidentifier'] == 'W1715894'

            gene_string = if test_string.scan(CONFIRMATION_SEQ_NGS_CASE).size.positive?
                            geno_str
                          else
                            test_string
                          end
            case gene_string
            when /BRCA1|BC1/i
              positive_gene << 'BRCA1'
            when /BRCA2|BC2/i
              positive_gene << 'BRCA2'
            when /PALB2|Variant\s+1/i
              positive_gene << 'PALB2'
            when /BRIP1/i
              positive_gene << 'BRIP1'
            when /MLH1/i
              positive_gene << 'MLH1'
            when /MSH6/i
              positive_gene << 'MSH6'
            when /MSH2/i
              positive_gene << 'MSH2'
            end
            positive_gene
          end
          # rubocop:enable Metrics/MethodLength, Metrics/CyclomaticComplexity

          def extract_teststatus(genotype, record)
            status = record.raw_fields['status']&.downcase
            geno_str = record.raw_fields['genotype']
            if POSITIVE_STATUS.include?(status)
              genotype.add_status(:positive)
            elsif NEGATIVE_STATUS.include?(status)
              genotype.add_status(:negative)
            elsif FAILED_TEST.match(record.raw_fields['status'])
              genotype.add_status(:failed)
            elsif UNKNOWN_STATUS.include?(status)
              genotype.add_status(:unknown)
            elsif GENO_DEPEND_STATUS.include?(status)
              teststatus = geno_str.blank? ? :negative : :positive
              genotype.add_status(teststatus)
            end
            @logger.debug "#{genotype.attribute_map['teststatus']} status for : #{status}"
          end
        end
      end
    end
  end
end
