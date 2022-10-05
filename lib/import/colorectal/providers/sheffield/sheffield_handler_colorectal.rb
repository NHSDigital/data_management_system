require 'pry'
require 'possibly'

module Import
  module Colorectal
    module Providers
      module Sheffield
        # Process Sheffield-specific record details into generalized internal genotype format
        class SheffieldHandlerColorectal < Import::Germline::ProviderHandler
          include Import::Helpers::Colorectal::Providers::Rcu::Constants

          def process_fields(record)
            genotype_str = record.raw_fields['genetictestscope'].strip
            return if NON_CRC_GENTICTESCOPE.include? genotype_str.downcase

            genocolorectal = Import::Colorectal::Core::Genocolorectal.new(record)
            genocolorectal.add_passthrough_fields(record.mapped_fields,
                                                  record.raw_fields,
                                                  PASS_THROUGH_FIELDS_COLO)
            add_test_scope_from_geno_karyo(genocolorectal, record)
            add_organisationcode_testresult(genocolorectal)
            add_test_type(genocolorectal, record)
            results = process_variants_from_record(genocolorectal, record)
            results.each { |cur_genotype| @persister.integrate_and_store(cur_genotype) }
          end

          def add_organisationcode_testresult(genocolorectal)
            genocolorectal.attribute_map['organisationcode_testresult'] = '699D0'
          end

          def add_test_scope_from_geno_karyo(genocolorectal, record)
            genotype_str = record.raw_fields['genetictestscope'].strip
            karyo = record.raw_fields['karyotypingmethod'].strip
            moleculartestingtype = record.raw_fields['moleculartestingtype'].strip
            process_method = GENETICTESTSCOPE_METHOD_MAPPING[genotype_str.downcase]
            if process_method
              public_send(process_method, karyo, genocolorectal, moleculartestingtype)
            else
              genocolorectal.add_test_scope(:no_genetictestscope)
            end
          end

          def process_scope_colorectal_panel(karyo, genocolorectal, moleculartestingtype)
            if COLO_PANEL_GENE_MAPPING_FS.keys.include? karyo
              @logger.debug "ADDED FULL_SCREEN TEST for: #{karyo}"
              genocolorectal.add_test_scope(:full_screen)
              @genes_set = COLO_PANEL_GENE_MAPPING_FS[karyo]
            elsif COLO_PANEL_GENE_MAPPING_TAR.keys.include? karyo
              @logger.debug "ADDED TARGETED TEST for: #{karyo}"
              genocolorectal.add_test_scope(:targeted_mutation)
              @genes_set = COLO_PANEL_GENE_MAPPING_TAR[karyo]
            elsif 'Default' == karyo
              scope = MOLECULAR_SCOPE_MAPPING[moleculartestingtype.downcase]
              genocolorectal.add_test_scope(scope)
              @genes_set = %w[APC MUTYH]
            else
              genocolorectal.add_test_scope(:no_genetictestscope)
            end
          end

          def process_scope_r209(karyo, genocolorectal, _moleculartestingtype)
            if R209_PANEL_GENE_MAPPING_FS.keys.include? karyo
              @logger.debug "ADDED FULL_SCREEN TEST for: #{karyo}"
              genocolorectal.add_test_scope(:full_screen)
              @genes_set = R209_PANEL_GENE_MAPPING_FS[karyo]
            elsif R209_PANEL_GENE_MAPPING_TAR.keys.include? karyo
              @logger.debug "ADDED TARGETED TEST for: #{karyo}"
              genocolorectal.add_test_scope(:targeted_mutation)
              @genes_set = R209_PANEL_GENE_MAPPING_TAR[karyo]
            else
              genocolorectal.add_test_scope(:no_genetictestscope)
            end
          end

          def process_scope_r210(karyo, genocolorectal, moleculartestingtype)
            if R210_PANEL_GENE_MAPPING_FS.keys.include? karyo
              @logger.debug "ADDED FULL_SCREEN TEST for: #{karyo}"
              genocolorectal.add_test_scope(:full_screen)
              @genes_set = R210_PANEL_GENE_MAPPING_FS[karyo]
            elsif R210_PANEL_GENE_MAPPING_TAR.keys.include? karyo
              @logger.debug "ADDED TARGETED TEST for: #{karyo}"
              genocolorectal.add_test_scope(:targeted_mutation)
              @genes_set = R210_PANEL_GENE_MAPPING_TAR[karyo]
            elsif R210_PANEL_GENE_MAPPING_MOL.keys.include? karyo
              genocolorectal.add_test_scope(MOLECULAR_SCOPE_MAPPING[moleculartestingtype.downcase])
              @genes_set = R210_PANEL_GENE_MAPPING_MOL[karyo]
            else
              genocolorectal.add_test_scope(:no_genetictestscope)
            end
          end

          def process_scope_r211(karyo, genocolorectal, moleculartestingtype)
            if R211_PANEL_GENE_MAPPING_FS.keys.include? karyo
              @logger.debug "ADDED FULL_SCREEN TEST for: #{karyo}"
              genocolorectal.add_test_scope(:full_screen)
              @genes_set = R211_PANEL_GENE_MAPPING_FS[karyo]
            elsif R211_PANEL_GENE_MAPPING_TAR.keys.include? karyo
              @logger.debug "ADDED TARGETED TEST for: #{karyo}"
              genocolorectal.add_test_scope(:targeted_mutation)
              @genes_set = R211_PANEL_GENE_MAPPING_TAR[karyo]
            elsif R211_PANEL_GENE_MAPPING_MOL.keys.include? karyo
              genocolorectal.add_test_scope(MOLECULAR_SCOPE_MAPPING[moleculartestingtype.downcase])
              @genes_set = R211_PANEL_GENE_MAPPING_MOL[karyo]
            else
              genocolorectal.add_test_scope(:no_genetictestscope)
            end
          end

          def process_scope_fap_familial(karyo, genocolorectal, _moleculartestingtype)
            if FAP_FAM_PANEL_GENE_MAPPING_TAR.keys.include? karyo
              @logger.debug "ADDED TARGETED TEST for: #{karyo}"
              genocolorectal.add_test_scope(:targeted_mutation)
              @genes_set = FAP_FAM_PANEL_GENE_MAPPING_TAR[karyo]
            else
              genocolorectal.add_test_scope(:no_genetictestscope)
            end
          end

          def process_scope_fap(karyo, genocolorectal, moleculartestingtype)
            if FAP_PANEL_GENE_MAPPING_MOL.keys.include? karyo
              genocolorectal.add_test_scope(MOLECULAR_SCOPE_MAPPING[moleculartestingtype.downcase])
              @genes_set = FAP_PANEL_GENE_MAPPING_MOL[karyo]
            else
              genocolorectal.add_test_scope(:no_genetictestscope)
            end
          end

          def process_scope_hnpcc(karyo, genocolorectal, moleculartestingtype)
            return if HNPCC_NON_GRMLINE.include? karyo

            if HNPCC_PANEL_GENE_MAPPING_FS.keys.include? karyo
              @logger.debug "ADDED FULL_SCREEN TEST for: #{karyo}"
              genocolorectal.add_test_scope(:full_screen)
              @genes_set = HNPCC_PANEL_GENE_MAPPING_FS[karyo]
            elsif HNPCC_PANEL_GENE_MAPPING_TAR.keys.include? karyo
              @logger.debug "ADDED TARGETED TEST for: #{karyo}"
              genocolorectal.add_test_scope(:targeted_mutation)
              @genes_set = HNPCC_PANEL_GENE_MAPPING_TAR[karyo]
            elsif HNPCC_PANEL_GENE_MAPPING_MOL.keys.include? karyo
              genocolorectal.add_test_scope(MOLECULAR_SCOPE_MAPPING[moleculartestingtype.downcase])
              @genes_set = HNPCC_PANEL_GENE_MAPPING_MOL[karyo]
            else
              genocolorectal.add_test_scope(:no_genetictestscope)
            end
          end

          def process_scope_myh(karyo, genocolorectal, moleculartestingtype)
            if 'Default' == karyo
              scope = MOLECULAR_SCOPE_MAPPING[moleculartestingtype.downcase]
              @logger.debug "ADDED #{scope} TEST for: #{moleculartestingtype}"
              genocolorectal.add_test_scope(scope)
              @genes_set = %w[APC MUTYH]
            else
              genocolorectal.add_test_scope(:no_genetictestscope)
            end
          end

          def process_scope_colo_ovarian_panel(karyo, genocolorectal, _moleculartestingtype)
            if OVRN_COLO_PNL_GENE_MAPPING.keys.include? karyo
              @logger.debug "ADDED FULL_SCREEN for: #{karyo}"
              genocolorectal.add_test_scope(:full_screen)
              @genes_set = OVRN_COLO_PNL_GENE_MAPPING[karyo]
            else
              genocolorectal.add_test_scope(:no_genetictestscope)
            end
          end

          def add_test_type(genocolorectal, record)
            moltestingtype = record.raw_fields['moleculartestingtype']

            genocolorectal.add_molecular_testing_type_strict(TEST_TYPE_MAPPING_COLO[moltestingtype.
              downcase])
          end

          def process_variants_from_record(genocolorectal, record)
            genocolorectals = []
            if full_screen?(genocolorectal)
              process_fullscreen_records(genocolorectal, record, genocolorectals)
            elsif targeted?(genocolorectal) || no_scope?(genocolorectal)
              process_targeted_no_scope_records(genocolorectal, record, genocolorectals)
            end
            genocolorectals
          end

          def full_screen?(genocolorectal)
            return false if genocolorectal.attribute_map['genetictestscope'].nil?

            genocolorectal.attribute_map['genetictestscope'].scan(/Full screen/i).size.positive?
          end

          def targeted?(genocolorectal)
            return false if genocolorectal.attribute_map['genetictestscope'].nil?

            genocolorectal.attribute_map['genetictestscope'].scan(/Targeted/i).size.positive?
          end

          def no_scope?(genocolorectal)
            return false if genocolorectal.attribute_map['genetictestscope'].nil?

            genocolorectal.attribute_map['genetictestscope'].scan(/Unable/i).size.positive?
          end

          def process_fullscreen_records(genocolorectal, record, genocolorectals)
            genotype_str = record.raw_fields['genotype']
            if normal?(genotype_str)
              process_normal_full_screen(genocolorectal, genocolorectals)
            elsif positive_cdna?(genotype_str) || positive_exonvariant?(genotype_str)
              process_variant_fs_records(genocolorectal, record, genocolorectals)
            elsif only_protein_impact?(genotype_str)
              process_only_protein_rec(genocolorectal, record, genocolorectals)
              positive_gene = get_gene(record)
              negative_genes = @genes_set - positive_gene
              add_other_genes_with_status(negative_genes, genocolorectal, genocolorectals, 1)
            elsif genotype_str.scan(/see\sbelow|comments/ix).size.positive?
              add_other_genes_with_status(@genes_set, genocolorectal, genocolorectals, 4)
            end
          end

          def process_targeted_no_scope_records(genocolorectal, record, genocolorectals)
            genotype_str = record.raw_fields['genotype']
            if normal?(genotype_str)
              process_normal_targeted(genocolorectal, record, genocolorectals)
            elsif positive_cdna?(genotype_str) || positive_exonvariant?(genotype_str)
              process_variant_targeted(genocolorectal, record, genocolorectals)
            elsif only_protein_impact?(genotype_str)
              process_only_protein_rec(genocolorectal, record, genocolorectals)
            end
          end

          def normal?(genotype_str)
            genotype_str.scan(NORMAL_VAR_REGEX).size.positive?
          end

          def process_normal_targeted(genocolorectal, record, genocolorectals)
            gene = get_gene(record)
            gene = @genes_set&.size == 1 && gene.empty? ? @genes_set[0] : gene[0]
            genocolorectal.add_gene_colorectal(gene)
            genocolorectal.add_status(1)
            genocolorectals.append(genocolorectal)
            genocolorectals
          end

          def process_normal_full_screen(genocolorectal, genocolorectals)
            negative_genes = @genes_set
            add_other_genes_with_status(negative_genes, genocolorectal, genocolorectals, 1)
            genocolorectals
          end

          def add_other_genes_with_status(other_genes, genocolorectal, genocolorectals, status)
            other_genes.each do |gene|
              genotype_othr = genocolorectal.dup_colo
              @logger.debug "SUCCESSFUL gene parse for #{status} status for: #{gene}"
              genotype_othr.add_status(status)
              genotype_othr.add_gene_colorectal(gene)
              genotype_othr.add_protein_impact(nil)
              genotype_othr.add_gene_location(nil)
              genocolorectals.append(genotype_othr)
            end
            genocolorectals
          end

          def positive_cdna?(genotype_string)
            genotype_string.scan(CDNA_REGEX).size.positive?
          end

          def positive_exonvariant?(genotype_string)
            genotype_string.scan(EXON_VARIANT_REGEX).size.positive?
          end

          def process_variant_targeted(genocolorectal, record, genocolorectals)
            positive_gene = get_gene(record)
            genotype_str = record.raw_fields['genotype'].to_s
            mutation = get_cdna_mutation(genotype_str)
            protein = get_protein_impact(genotype_str)
            genotype_pos = genocolorectal.dup_colo
            genotype_pos.add_gene_location(mutation)
            genotype_pos.add_protein_impact(protein)
            genotype_pos.add_gene_colorectal(positive_gene[0]&.upcase)
            process_exons(genotype_pos, genotype_str)
            genocolorectals.append(genotype_pos)
          end

          def process_variant_fs_records(genocolorectal, record, genocolorectals)
            if (record.raw_fields['genotype'].scan(CDNA_REGEX).size +
                record.raw_fields['genotype'].scan(EXON_VARIANT_REGEX).size) > 1
              process_multiple_variant_fs_record(genocolorectal, record, genocolorectals)
            else
              process_single_variant_fs_record(genocolorectal, record, genocolorectals)
            end
          end

          def process_multiple_variant_fs_record(genocolorectal, record, genocolorectals)
            positive_gene = record.raw_fields['genotype'].scan(COLORECTAL_GENES_REGEX).flatten.uniq
            raw_genotypes = record.raw_fields['genotype'].split(positive_gene[-1]).
                            select(&:present?)
            if positive_gene.size < raw_genotypes.size
              # Same gene multi variants case
              raw_genotypes = record.raw_fields['genotype'].split(';')
            else
              # different gene multi variants case
              raw_genotypes[-1].prepend(positive_gene[-1])
            end
            process_raw_genotypes(raw_genotypes, genocolorectal, genocolorectals)
            negative_genes = @genes_set - positive_gene
            add_other_genes_with_status(negative_genes, genocolorectal, genocolorectals, 1)
          end

          def process_raw_genotypes(raw_genotypes, genocolorectal, genocolorectals)
            raw_genotypes.each do |raw_genotype|
              raw_genotype.scan(COLORECTAL_GENES_REGEX)
              genocolorectal_dup = genocolorectal.dup_colo
              genocolorectal_dup.add_gene_colorectal($LAST_MATCH_INFO[:colorectal]&.upcase)
              if positive_cdna?(raw_genotype) || positive_exonvariant?(raw_genotype)
                process_exons(genocolorectal_dup, raw_genotype)
                process_cdna_change(genocolorectal_dup, raw_genotype)
                process_protein_impact(genocolorectal_dup, raw_genotype)
                genocolorectal_dup.add_status(2)
              else
                genocolorectal_dup.add_status(1)
              end
              genocolorectals.append(genocolorectal_dup)
            end
            genocolorectals
          end

          def process_single_variant_fs_record(genocolorectal, record, genocolorectals)
            genotype_str = record.raw_fields['genotype'].to_s
            positive_gene = genotype_str.scan(COLORECTAL_GENES_REGEX).flatten.uniq

            if positive_gene.blank?
              add_other_genes_with_status(@genes_set, genocolorectal, genocolorectals, 4)
            else
              genocolorectal_pos = genocolorectal.dup_colo
              genocolorectal_pos.add_gene_location(get_cdna_mutation(genotype_str))
              genocolorectal_pos.add_protein_impact(get_protein_impact(genotype_str))
              genocolorectal_pos.add_gene_colorectal(positive_gene[0]&.upcase)
              process_exons(genocolorectal_pos, genotype_str)
              genocolorectals.append(genocolorectal_pos)
              negative_genes = @genes_set - positive_gene
              add_other_genes_with_status(negative_genes, genocolorectal, genocolorectals, 1)
            end

            genocolorectals
          end

          def only_protein_impact?(genotype_str)
            genotype_str.scan(CDNA_REGEX).size.zero? &&
              genotype_str.scan(EXON_VARIANT_REGEX).size.zero? &&
              genotype_str.scan(PROTEIN_REGEX).size.positive?
          end

          def process_only_protein_rec(genocolorectal, record, genocolorectals)
            genotype_str = record.raw_fields['genotype']
            gene = get_gene(record)
            genocolorectal.add_gene_colorectal(gene[0]&.upcase)
            genocolorectal.add_status(2)
            genocolorectal.add_gene_location('')
            process_protein_impact(genocolorectal, genotype_str)
            genocolorectals.append(genocolorectal)
            genocolorectals
          end

          def get_gene(record)
            genotype_str = record.raw_fields['genotype'].to_s
            positive_gene = genotype_str.scan(COLORECTAL_GENES_REGEX).flatten.uniq
            if positive_gene.size.zero?
              positive_gene = record.raw_fields['karyotypingmethod'].
                              scan(COLORECTAL_GENES_REGEX).flatten.uniq
            end
            positive_gene
          end

          def get_protein_impact(raw_genotype)
            raw_genotype.match(PROTEIN_REGEX)
            $LAST_MATCH_INFO[:impact] unless $LAST_MATCH_INFO.nil?
          end

          def get_cdna_mutation(raw_genotype)
            raw_genotype.match(CDNA_REGEX)
            $LAST_MATCH_INFO[:cdna] unless $LAST_MATCH_INFO.nil?
          end

          def process_cdna_change(genocolorectal, genotype_str)
            case genotype_str
            when CDNA_REGEX
              genocolorectal.add_gene_location($LAST_MATCH_INFO[:cdna])
              @logger.debug "SUCCESSFUL cdna change parse for: #{$LAST_MATCH_INFO[:cdna]}"
              genocolorectal.add_status(:positive)
            else
              @logger.debug "FAILED cdna change parse for: #{genotype_str}"
            end
          end

          def process_protein_impact(genocolorectal, genotype_str)
            case genotype_str
            when PROTEIN_REGEX
              genocolorectal.add_protein_impact($LAST_MATCH_INFO[:impact])
              genocolorectal.add_status(:positive)
              @logger.debug "SUCCESSFUL protein change parse for: #{$LAST_MATCH_INFO[:impact]}"
            else
              @logger.debug "FAILED protein change parse for: #{genotype_str}"
            end
          end

          def process_exons(genocolorectal, genotype_str)
            exon_matches = EXON_VARIANT_REGEX.match(genotype_str)
            return if exon_matches.nil?

            genocolorectal.add_exon_location($LAST_MATCH_INFO[:exons])
            if exon_matches.names.include? 'mutationtype'
              Maybe(exon_matches[:mutationtype]).map do |mutationtype|
                genocolorectal.add_variant_type(mutationtype)
              end
            end
            if exon_matches.names.include? 'zygosity'
              Maybe(exon_matches[:zygosity]).map do |zygosity|
                genocolorectal.add_zygosity(zygosity)
              end
            end
            genocolorectal.add_status(2)
            @logger.debug "SUCCESSFUL exon extraction for: #{genotype_str}"
          end
        end
      end
    end
  end
end
