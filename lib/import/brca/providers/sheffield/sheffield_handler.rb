require 'pry'
require 'possibly'

module Import
  module Brca
    module Providers
      module Sheffield
        # Process Sheffield-specific record details into generalized internal genotype format
        class SheffieldHandler < Import::Germline::ProviderHandler
          include Import::Helpers::Brca::Providers::Rcu::RcuConstants

          def process_fields(record)
            geno = record.raw_fields['genetictestscope']
            return if NON_BRCA_SCOPE.include?(geno)

            genotype = Import::Brca::Core::GenotypeBrca.new(record)
            genotype.add_passthrough_fields(record.mapped_fields,
                                            record.raw_fields,
                                            PASS_THROUGH_FIELDS)
            add_test_type(genotype, record)
            add_organisationcode_testresult(genotype)
            add_test_scope_from_geno_karyo(genotype, record)

            res = process_variants_from_record(genotype, record)
            res.map { |cur_genotype| @persister.integrate_and_store(cur_genotype) }
          end

          def add_organisationcode_testresult(genotype)
            genotype.attribute_map['organisationcode_testresult'] = '699D0'
          end

          def add_test_scope_from_geno_karyo(genotype, record)
            genotype_str = record.raw_fields['genetictestscope'].strip
            karyo = record.raw_fields['karyotypingmethod'].strip
            process_method = GENETICTESTSCOPE_METHOD_MAPPING[genotype_str]
            if process_method
              send(process_method, karyo, genotype)
            else
              genotype.add_test_scope(:no_genetictestscope)
            end
          end

          def process_scope_familial_mutation(karyo, genotype)
            if BRCA_FAMILIAL_GENE_MAPPING.keys.include? karyo
              @logger.debug "ADDED TARGETED TEST for: #{karyo}"
              genotype.add_test_scope(:targeted_mutation)
              @genes_set = BRCA_FAMILIAL_GENE_MAPPING[karyo]
            else
              genotype.add_test_scope(:no_genetictestscope)
            end
          end

          def process_scope_gene_analysis(karyo, genotype)
            if BRCA_ANALYSIS_GENE_MAPPING_FS.keys.include? karyo
              @logger.debug "ADDED FULL_SCREEN TEST for: #{karyo}"
              genotype.add_test_scope(:full_screen)
              @genes_set = BRCA_ANALYSIS_GENE_MAPPING_FS[karyo]
            elsif BRCA_ANALYSIS_GENE_MAPPING_TAR.keys.include? karyo
              @logger.debug "ADDED TARGETED TEST for: #{karyo}"
              genotype.add_test_scope(:targeted_mutation)
              @genes_set = BRCA_ANALYSIS_GENE_MAPPING_TAR[karyo]
            else
              genotype.add_test_scope(:no_genetictestscope)
            end
          end

          def process_scope_ovarian_panel(karyo, genotype)
            if OVRN_CNCR_PNL_GENE_MAPPING.keys.include? karyo
              @logger.debug "ADDED FULL_SCREEN for: #{karyo}"
              genotype.add_test_scope(:full_screen)
              @genes_set = OVRN_CNCR_PNL_GENE_MAPPING[karyo]
            else
              genotype.add_test_scope(:no_genetictestscope)
            end
          end

          def process_scope_colo_ovarian_panel(karyo, genotype)
            if OVRN_COLO_PNL_GENE_MAPPING.keys.include? karyo
              @logger.debug "ADDED FULL_SCREEN for: #{karyo}"
              genotype.add_test_scope(:full_screen)
              @genes_set = OVRN_COLO_PNL_GENE_MAPPING[karyo]
            else
              genotype.add_test_scope(:no_genetictestscope)
            end
          end

          def process_scope_r205(karyo, genotype)
            if R205_GENE_MAPPING_FS.keys.include? karyo
              @logger.debug "ADDED FULL_SCREEN TEST for: #{karyo}"
              genotype.add_test_scope(:full_screen)
              @genes_set = R205_GENE_MAPPING_FS[karyo]
            elsif R205_GENE_MAPPING_TAR.keys.include? karyo
              @logger.debug "ADDED TARGETED TEST for: #{karyo}"
              genotype.add_test_scope(:targeted_mutation)
              @genes_set = R205_GENE_MAPPING_TAR[karyo]
            else
              genotype.add_test_scope(:no_genetictestscope)
            end
          end

          def process_scope_r206(karyo, genotype)
            if R206_GENE_MAPPING.keys.include? karyo
              @logger.debug "ADDED FULL_SCREEN TEST for: #{karyo}"
              genotype.add_test_scope(:full_screen)
              @genes_set = R206_GENE_MAPPING[karyo]
            elsif ['R242.1 :: Predictive testing'].include? karyo
              @logger.debug "ADDED TARGETED TEST for: #{karyo}"
              genotype.add_test_scope(:targeted_mutation)
              @genes_set = %w[ATM BRCA1 BRCA2 BRIP1 CDH1 CHEK2 EPCAM MLH1 MSH2 MSH6 PALB2 PTEN
                              RAD51C RAD51D STK11 TP53 PMS2]
            else
              genotype.add_test_scope(:no_genetictestscope)
            end
          end

          def process_scope_r207(karyo, genotype)
            if R207_GENE_MAPPING_FS.keys.include? karyo
              @logger.debug "ADDED FULL_SCREEN TEST for: #{karyo}"
              genotype.add_test_scope(:full_screen)
              @genes_set = R207_GENE_MAPPING_FS[karyo]
            elsif R207_GENE_MAPPING_TAR.keys.include? karyo
              @logger.debug "ADDED TARGETED TEST for: #{karyo}"
              genotype.add_test_scope(:targeted_mutation)
              @genes_set = R207_GENE_MAPPING_TAR[karyo]
            else
              genotype.add_test_scope(:no_genetictestscope)
            end
          end

          def process_scope_r208(karyo, genotype)
            if R208_GENE_MAPPING_FS.keys.include? karyo
              @logger.debug "ADDED FULL_SCREEN TEST for: #{karyo}"
              genotype.add_test_scope(:full_screen)
              @genes_set = R208_GENE_MAPPING_FS[karyo]
            elsif R208_GENE_MAPPING_TAR.keys.include? karyo
              @logger.debug "ADDED TARGETED TEST for: #{karyo}"
              genotype.add_test_scope(:targeted_mutation)
              @genes_set = R208_GENE_MAPPING_TAR[karyo]
            else
              genotype.add_test_scope(:no_genetictestscope)
            end
          end

          def process_scope_r240(karyo, genotype)
            if R240_GENE_MAPPING_TAR.keys.include? karyo
              @logger.debug "ADDED TARGETED TEST for: #{karyo}"
              genotype.add_test_scope(:targeted_mutation)
              @genes_set = R240_GENE_MAPPING_TAR[karyo]
            else
              genotype.add_test_scope(:no_genetictestscope)
            end
          end

          def process_scope_r242(karyo, genotype)
            if R242_GENE_MAPPING_TAR.keys.include? karyo
              @logger.debug "ADDED TARGETED TEST for: #{karyo}"
              genotype.add_test_scope(:targeted_mutation)
              @genes_set = R242_GENE_MAPPING_TAR[karyo]
            else
              genotype.add_test_scope(:no_genetictestscope)
            end
          end

          def add_test_type(genotype, record)
            Maybe(record.raw_fields['moleculartestingtype']).each do |type|
              genotype.add_molecular_testing_type_strict(TEST_TYPE_MAPPING[type.strip])
            end
          end

          def process_variants_from_record(genotype, record)
            genotypes = []
            if full_screen?(genotype)
              process_fullscreen_records(genotype, record, genotypes)
            elsif targeted?(genotype) || no_scope?(genotype)
              process_targeted_no_scope_records(genotype, record, genotypes)
            end
            genotypes
          end

          def full_screen?(genotype)
            return if genotype.attribute_map['genetictestscope'].nil?

            genotype.attribute_map['genetictestscope'].scan(/Full screen/i).size.positive?
          end

          def targeted?(genotype)
            return if genotype.attribute_map['genetictestscope'].nil?

            genotype.attribute_map['genetictestscope'].scan(/Targeted/i).size.positive?
          end

          def no_scope?(genotype)
            return if genotype.attribute_map['genetictestscope'].nil?

            genotype.attribute_map['genetictestscope'].scan(/Unable to assign/i).size.positive?
          end

          # rubocop:disable Metrics/MethodLength disabled as rubcop reduces redability if the method
          def process_targeted_no_scope_records(genotype, record, genotypes)
            genotype_str = record.raw_fields['genotype']
            positive_genes = genotype_str.scan(BRCA_REGEX).flatten.uniq
            if positive_genes.size > 1
              process_multi_genes(genotype, record, genotypes)
            elsif positive_cdna?(genotype_str) || positive_exonvariant?(genotype_str)
              process_single_variant(genotype, record, genotypes)
            elsif normal?(record)
              process_normal_targeted(genotype, record, genotypes)
            elsif failed_test?(record)
              process_failed_targeted(genotype, record, genotypes)
            elsif only_protein_impact?(record)
              process_protein_targeted(genotype, record, genotypes)
            elsif stated_detected_only?(record)
              process_stated_detected_targeted(genotype, record, genotypes)
            else
              process_unknown_targeted(genotype, record, genotypes)
            end
            genotypes
          end
          # rubocop:enable Metrics/MethodLength

          def process_normal_targeted(genotype, record, genotypes)
            process_single_gene(genotype, record)
            genotype.add_status(1)
            genotypes.append(genotype)
            genotypes
          end

          def process_failed_targeted(genotype, record, genotypes)
            process_single_gene(genotype, record)
            genotype.add_status(9)
            genotypes.append(genotype)
            genotypes
          end

          def process_protein_targeted(genotype, record, genotypes)
            genotype_str = record.raw_fields['genotype']
            process_single_gene(genotype, record)
            genotype.add_status(2)
            genotype.add_gene_location('')
            process_protein_impact(genotype, genotype_str)
            genotypes.append(genotype)
            genotypes
          end

          def process_stated_detected_targeted(genotype, record, genotypes)
            process_single_gene(genotype, record)
            genotype.add_status(2)
            genotype.add_gene_location('')
            genotype.add_protein_impact('')
            genotypes.append(genotype)
            genotypes
          end

          def process_unknown_targeted(genotype, record, genotypes)
            process_single_gene(genotype, record)
            genotype.add_status(4)
            genotypes.append(genotype)
            genotypes
          end

          def process_positive_targeted(genotype, record, genotypes)
            genotype_str = record.raw_fields['genotype']
            if genotype_str.scan(CDNA_REGEX).size > 1
              process_multi_genes(genotype, record, genotypes)
            else
              process_single_gene(genotype, record)
              process_protein_impact(genotype, genotype_str)
              process_cdna_change(genotype, genotype_str)
              process_exons(genotype, genotype_str)
              genotypes.append(genotype)
            end
            genotypes
          end

          def process_single_gene(genotype, record)
            positive_genes = get_gene(record)
            genotype.add_gene(positive_genes[0]&.upcase) if positive_genes.present?
            return if positive_genes.blank?

            @logger.debug "SUCCESSFUL gene parse for: #{positive_genes[0]&.upcase}"
          end

          def add_other_genes_with_status(other_genes, genotype, genotypes, status)
            other_genes.each do |gene|
              genotype_other = genotype.dup
              @logger.debug "SUCCESSFUL gene parse for #{status} status for: #{gene}"
              genotype_other.add_status(status)
              genotype_other.add_gene(gene)
              genotype_other.add_protein_impact(nil)
              genotype_other.add_gene_location(nil)
              genotypes.append(genotype_other)
            end
            genotypes
          end

          def process_multi_genes(genotype, record, genotypes)
            positive_genes = record.raw_fields['genotype'].scan(BRCA_REGEX).flatten.uniq
            raw_genotypes = record.raw_fields['genotype'].split(positive_genes[-1])
            raw_genotypes[1].prepend(positive_genes[-1])
            process_raw_genotypes(raw_genotypes, genotype, genotypes)
          end

          def process_raw_genotypes(raw_genotypes, genotype, genotypes)
            raw_genotypes.each do |raw_genotype|
              raw_genotype.scan(BRCA_REGEX)
              genotype_dup = genotype.dup
              genotype_dup.add_gene($LAST_MATCH_INFO[:brca]&.upcase)
              if positive_cdna?(raw_genotype) || positive_exonvariant?(raw_genotype)
                process_exons(genotype_dup, raw_genotype)
                process_cdna_change(genotype_dup, raw_genotype)
                process_protein_impact(genotype_dup, raw_genotype)
                genotype_dup.add_status(2)
              else
                genotype_dup.add_status(1)
              end
              genotypes.append(genotype_dup)
            end
            genotypes
          end

          def process_single_variant(genotype, record, genotypes)
            positive_genes = get_gene(record)

            if positive_genes.one?
              process_positive_record(genotype, record, genotypes, positive_genes)
            else
              process_unknown_status_record(genotype, genotypes)
            end
            genotypes
          end

          def process_fullscreen_records(genotype, record, genotypes)
            genotype_str = record.raw_fields['genotype']
            if mlpa_fail?(record)
              process_mlpa_fail_full_screen(genotype, record, genotypes)
            elsif normal?(record)
              process_normal_full_screen(genotype, record, genotypes)
            elsif failed_test?(record)
              process_failed_full_screen(genotype, record, genotypes)
            elsif positive_cdna?(genotype_str) || positive_exonvariant?(genotype_str)
              process_variant_fs_records(genotype, record, genotypes)
            elsif only_protein_impact?(record) ||
                  genotype_str.scan(/see\sbelow|comments/ix).size.positive?
              add_other_genes_with_status(@genes_set, genotype, genotypes, 4)
            end
            genotypes
          end

          def process_variant_fs_records(genotype, record, genotypes)
            if (record.raw_fields['genotype'].scan(CDNA_REGEX).size +
                record.raw_fields['genotype'].scan(EXON_VARIANT_REGEX).size) > 1
              process_multiple_variant_fs_record(genotype, record, genotypes)
            else
              process_single_variant_fs_record(genotype, record, genotypes)
            end
          end

          def process_multiple_variant_fs_record(genotype, record, genotypes)
            positive_genes = record.raw_fields['genotype'].scan(BRCA_REGEX).flatten.uniq
            if positive_genes.blank?
              add_other_genes_with_status(@genes_set, genotype, genotypes, 4)
            elsif positive_genes.size > 1
              process_multi_genes(genotype, record, genotypes)
            else
              process_positive_record(genotype, record, genotypes, positive_genes)
            end
            negative_genes = @genes_set - positive_genes
            add_other_genes_with_status(negative_genes, genotype, genotypes, 1)
            genotypes
          end

          def process_single_variant_fs_record(genotype, record, genotypes)
            genotype_str = record.raw_fields['genotype'].to_s
            positive_genes = genotype_str.scan(BRCA_REGEX).flatten.uniq

            if positive_genes.blank?
              add_other_genes_with_status(@genes_set, genotype, genotypes, 4)
            else
              process_positive_record(genotype, record, genotypes, positive_genes)
              negative_genes = @genes_set - positive_genes
              add_other_genes_with_status(negative_genes, genotype, genotypes, 1)
            end

            genotypes
          end

          def process_positive_record(genotype, record, genotypes, positive_gene)
            genotype_str = record.raw_fields['genotype'].to_s
            mutation = get_cdna_mutation(genotype_str)
            protein = get_protein_impact(genotype_str)
            genotype_pos = genotype.dup
            genotype_pos.add_gene_location(mutation)
            genotype_pos.add_protein_impact(protein)
            genotype_pos.add_gene(positive_gene[0]&.upcase)
            process_exons(genotype_pos, genotype_str)
            genotypes.append(genotype_pos)
          end

          def process_unknown_status_record(genotype, genotypes)
            genotype.add_status(4)
            genotypes.append(genotype)
            genotypes
          end

          def normal?(record)
            variant = record.raw_fields['genotype'].strip
            variant.scan(NORMAL_VAR_REGEX).size.positive?
          end

          def process_normal_full_screen(genotype, _record, genotypes)
            negative_genes = @genes_set
            add_other_genes_with_status(negative_genes, genotype, genotypes, 1)
            genotypes
          end

          def failed_test?(record)
            record.raw_fields['genotype'].scan(/Fail/i).size.positive?
          end

          def process_failed_full_screen(genotype, record, genotypes)
            geno = record.raw_fields['genotype'].to_s
            failed_gene = geno.scan(BRCA_REGEX).flatten.uniq.join
            if failed_gene.blank?
              add_other_genes_with_status(@genes_set, genotype, genotypes, 9)
            else
              genotype.add_gene(failed_gene&.upcase)
              genotype.add_status(9)
              genotypes.append(genotype)
              negative_genes = @genes_set - [failed_gene]
              add_other_genes_with_status(negative_genes, genotype, genotypes, 1)
            end

            genotypes
          end

          def mlpa_fail?(record)
            record.raw_fields['genotype'].scan(MLPA_FAIL_REGEX).size.positive?
          end

          def process_mlpa_fail_full_screen(genotype, record, genotypes)
            geno = record.raw_fields['genotype'].to_s
            mlpa_genes = geno.scan(BRCA_REGEX).flatten.uniq

            if mlpa_genes.blank?
              add_other_genes_with_status(@genes_set, genotype, genotypes, 9)
            else
              process_mlpa_genes(mlpa_genes, genotype, genotypes)
              negative_genes = @genes_set - mlpa_genes
              add_other_genes_with_status(negative_genes, genotype, genotypes, 1)
            end
            genotypes
          end

          def process_mlpa_genes(mlpa_genes, genotype, genotypes)
            mlpa_genes.each do |mlpa_fail_gene|
              genotype_dup = genotype.dup
              genotype_dup.add_gene(mlpa_fail_gene&.upcase)
              genotype_dup.add_method('mlpa')
              genotype_dup.add_status(9)
              genotypes.append(genotype_dup)
            end
          end

          def positive_cdna?(genotype_string)
            genotype_string.scan(CDNA_REGEX).size.positive?
          end

          def positive_exonvariant?(genotype_string)
            genotype_string.scan(EXON_VARIANT_REGEX).size.positive?
          end

          def get_protein_impact(raw_genotype)
            raw_genotype.match(PROTEIN_REGEX)
            $LAST_MATCH_INFO[:impact] unless $LAST_MATCH_INFO.nil?
          end

          def get_cdna_mutation(raw_genotype)
            raw_genotype.match(CDNA_REGEX)
            $LAST_MATCH_INFO[:cdna] unless $LAST_MATCH_INFO.nil?
          end

          def get_gene(record)
            genotype_str = record.raw_fields['genotype'].to_s
            positive_genes = genotype_str.scan(BRCA_REGEX).flatten.uniq
            if positive_genes.size.zero?
              positive_genes = record.raw_fields['karyotypingmethod'].scan(BRCA_REGEX).flatten.uniq
            end
            positive_genes
          end

          def only_protein_impact?(record)
            variant = record.raw_fields['genotype']
            variant.scan(CDNA_REGEX).size.zero? &&
              variant.scan(EXON_VARIANT_REGEX).size.zero? &&
              variant.scan(PROTEIN_REGEX).size.positive?
          end

          def stated_detected_only?(record)
            variant = record.raw_fields['genotype']
            ['Familial mutation detected',
             'Familial pathogenic mutation detected'].include? variant
          end

          def process_cdna_change(genotype, genotype_str)
            case genotype_str
            when CDNA_REGEX
              genotype.add_gene_location($LAST_MATCH_INFO[:cdna])
              @logger.debug "SUCCESSFUL cdna change parse for: #{$LAST_MATCH_INFO[:cdna]}"
              genotype.add_status(:positive)
            else
              @logger.debug "FAILED cdna change parse for: #{genotype_str}"
            end
          end

          def process_protein_impact(genotype, genotype_str)
            case genotype_str
            when PROTEIN_REGEX
              genotype.add_protein_impact($LAST_MATCH_INFO[:impact])
              genotype.add_status(:positive)
              @logger.debug "SUCCESSFUL protein change parse for: #{$LAST_MATCH_INFO[:impact]}"
            else
              @logger.debug "FAILED protein change parse for: #{genotype_str}"
            end
          end

          def process_exons(genotype, genotype_str)
            exon_matches = EXON_VARIANT_REGEX.match(genotype_str)
            return if exon_matches.nil?

            genotype.add_exon_location($LAST_MATCH_INFO[:exons])
            Maybe(exon_matches[:mutationtype]).map { |x| genotype.add_variant_type(x) } if
            exon_matches.names.include? 'mutationtype'
            Maybe(exon_matches[:zygosity]).map { |x| genotype.add_zygosity(x) } if
            exon_matches.names.include? 'zygosity'
            genotype.add_status(2)
            @logger.debug "SUCCESSFUL exon extraction for: #{genotype_str}"
          end
        end
      end
    end
  end
end
