require 'possibly'
# require 'import/brca/providers/newcastle/newcastle_storage_manager'

module Import
  module Brca
    module Providers
      module Newcastle
        # rubocop:disable Metrics/ClassLength
        # Process Newcastle-specific record details into generalized internal genotype format
        class NewcastleHandler < Import::Germline::ProviderHandler
          include Import::Helpers::Brca::Providers::Rtd::RtdConstants

          def initialize(batch)
            @failed_variant_counter = 0
            @variants_processed_counter = 0
            super
          end

          def process_fields(record)
            genotype = Import::Brca::Core::GenotypeBrca.new(record)
            genotype.add_passthrough_fields(record.mapped_fields,
                                            record.raw_fields,
                                            PASS_THROUGH_FIELDS,
                                            FIELD_NAME_MAPPINGS)
            add_organisationcode_testresult(genotype)
            add_variantpathclass(genotype, record)
            process_test_scope(genotype, record)
            process_test_status(genotype, record)
            final_results = process_variant_records(genotype, record)
            final_results.each { |cur_genotype| @persister.integrate_and_store(cur_genotype) }
          end

          def add_organisationcode_testresult(genotype)
            genotype.attribute_map['organisationcode_testresult'] = '699A0'
          end

          def add_variantpathclass(genotype, record)
            genotype.add_variant_class(record.raw_fields['variantpathclass'])
          end

          def process_test_type(genotype, record)
            # cludge to handle their change in field mapping...
            reason = record.raw_fields['referral reason']
            unless reason.nil?
              genotype.add_molecular_testing_type_strict(
                TEST_TYPE_MAP[reason.downcase.strip]
              )
            end
            mtype = record.raw_fields['moleculartestingtype']
            return if mtype.nil?

            genotype.add_molecular_testing_type_strict(
              TEST_TYPE_MAP[mtype.downcase.strip]
            )
          end

          def process_test_scope(genotype, record)
            moleculartestingtype = record.raw_fields['moleculartestingtype']&.downcase&.strip
            investigationcode = record.raw_fields['investigation code']&.downcase&.strip
            servicecategory = record.raw_fields['service category']&.downcase&.strip

            if %w[o c a2].include?(servicecategory)
              add_scope_from_service_category(servicecategory, genotype)
            else
              add_scope_from_inv_code_mol_type(investigationcode, moleculartestingtype, genotype)
            end
          end

          def process_test_status(genotype, record)
            gene = record.raw_fields['gene']
            variant = get_variant(record)
            teststatus = record.raw_fields['teststatus']
            if gene.present? && variant.present? && pathogenic?(record)
              genotype.add_status(2)
            elsif gene.present? && variant.blank?
              genotype.add_status(4)
            elsif teststatus.present? && teststatus.scan(/fail/i).size.positive?
              genotype.add_status(9)
            else
              genotype.add_status(1)
            end
          end

          def process_variant_records(genotype, record)
            genotypes = []
            if full_screen?(genotype)
              process_fullscreen_records(genotype, record, genotypes)
            elsif targeted?(genotype) || no_scope?(genotype)
              process_targeted_screen(genotype, record, genotypes)
            end
            genotypes
          end

          def add_scope_from_service_category(service_category, genotype)
            if %w[o c].include? service_category
              @logger.debug 'Found O/C'
              genotype.add_test_scope(:full_screen)
            elsif service_category == 'a2'
              @logger.debug 'Found A2'
              genotype.add_test_scope(:targeted_mutation)
            else
              @logger.info 'Test scope not determined via service category'
            end
          end

          def add_scope_from_inv_code_mol_type(inv_code, mol_type, genotype)
            scope = TEST_SCOPE_MAP[inv_code].presence || TEST_SCOPE_FROM_TYPE_MAP[mol_type]
            genotype.add_test_scope(scope)
            @logger.info 'ADDED SCOPE FROM INVESTIGATION CODE/MOLECULAR TESTING TYPE'
          end

          def process_fullscreen_records(genotype, record, genotypes)
            gene = get_gene(record)
            genotype.add_gene(gene)
            variant = get_variant(record)
            if positive_rec?(record)
              add_fs_negative_gene(genotype, genotypes)
              process_variants(genotype, variant)
              genotypes.append(genotype)
            elsif gene.present? # for other status records
              genotypes.append(genotype)
              add_fs_negative_gene(genotype, genotypes)
            else
              process_null_gene_rec(genotype, genotypes)
            end

            genotypes
          end

          def add_fs_negative_gene(genotype, genotypes)
            if [7, 8].include? genotype.other_gene
              genotype_dup = genotype.dup
              genotype_dup.add_gene(genotype.other_gene)
              genotype_dup.add_status(1)
              genotypes.append(genotype_dup)
            else # if main gene is not 'BRCA1/BRCA2' then add 2 negative tests for them
              [7, 8].each do |gene|
                genotype_dup = genotype.dup
                genotype_dup.add_status(1)
                genotype_dup.add_gene(gene)
                genotypes.append(genotype_dup)
              end
            end
            genotypes
          end

          def process_null_gene_rec(genotype, genotypes)
            %w[BRCA1 BRCA2].each do |brca_gene|
              genotype_dup = genotype.dup
              genotype_dup.add_gene(brca_gene)
              genotypes.append(genotype_dup)
            end
          end

          def process_targeted_screen(genotype, record, genotypes)
            genotype.add_gene(get_gene(record))
            variant = get_variant(record)
            process_variants(genotype, variant) if positive_rec?(record)
            genotypes.append(genotype)
            genotypes
          end

          def get_gene(record)
            positive_genes = []
            gene = record.raw_fields['gene']
            positive_genes = gene.scan(BRCA_REGEX).flatten.uniq unless gene.nil?
            if positive_genes.size.zero?
              positive_genes = record.raw_fields['investigation code'].scan(BRCA_REGEX).flatten.uniq
            end
            positive_genes[0] unless positive_genes.nil?
          end

          def process_variants(genotype, variant)
            process_cdna_variant(genotype, variant)
            process_exonic_variant(genotype, variant)
            process_protein_impact(genotype, variant)
          end

          def get_variant(record)
            record.raw_fields['genotype'].presence || record.raw_fields['variant name']
          end

          def positive_rec?(record)
            gene = record.raw_fields['gene']
            variant = get_variant(record)
            return true if gene.present? && variant.present? && pathogenic?(record)
          end

          def full_screen?(genotype)
            return false if genotype.attribute_map['genetictestscope'].nil?

            genotype.attribute_map['genetictestscope'].scan(/Full screen/i).size.positive?
          end

          def targeted?(genotype)
            return false if genotype.attribute_map['genetictestscope'].nil?

            genotype.attribute_map['genetictestscope'].scan(/Targeted/i).size.positive?
          end

          def no_scope?(genotype)
            return false if genotype.attribute_map['genetictestscope'].nil?

            genotype.attribute_map['genetictestscope'].scan(/Unable/i).size.positive?
          end

          def positive_cdna?(variant)
            variant.scan(CDNA_REGEX).size.positive?
          end

          def positive_exonvariant?(variant)
            variant.scan(EXON_VARIANT_REGEX).size.positive?
          end

          def pathogenic?(record)
            varpathclass = record.raw_fields['variantpathclass']&.downcase
            return true if NON_PATHEGENIC_CODES.exclude? varpathclass

            false
          end

          def process_exonic_variant(genotype, variant)
            return unless variant.scan(EXON_VARIANT_REGEX).size.positive?

            genotype.add_exon_location($LAST_MATCH_INFO[:exons])
            genotype.add_variant_type($LAST_MATCH_INFO[:variant])
            @logger.debug "SUCCESSFUL exon variant parse for: #{variant}"
          end

          def process_cdna_variant(genotype, variant)
            return unless variant.scan(CDNA_REGEX).size.positive?

            genotype.add_gene_location($LAST_MATCH_INFO[:cdna])
            @logger.debug "SUCCESSFUL cdna change parse for: #{$LAST_MATCH_INFO[:cdna]}"
          end

          def process_protein_impact(genotype, variant)
            if variant.scan(PROTEIN_REGEX).size.positive?
              genotype.add_protein_impact($LAST_MATCH_INFO[:impact])
              @logger.debug "SUCCESSFUL protein parse for: #{$LAST_MATCH_INFO[:impact]}"
            else
              @logger.debug "FAILED protein parse for: #{variant}"
            end
          end

          def summarize
            @logger.info ' ************** Handler Summary **************** '
            @logger.info "Num bad variants: #{@failed_variant_counter} of "\
                         "#{@variants_processed_counter} processed"
          end
        end
        # rubocop:enable Metrics/ClassLength
      end
    end
  end
end
