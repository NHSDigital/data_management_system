require 'possibly'

module Import
  module Brca
    module Providers
      module Salisbury
        # Process Salisbury-specific record details into generalized internal genotype format
        class SalisburyHandler < Import::Germline::ProviderHandler
          include Import::Helpers::Brca::Providers::Rnz::RnzConstants

          def process_fields(record)
            genotype = Import::Brca::Core::GenotypeBrca.new(record)
            genotype.add_passthrough_fields(record.mapped_fields,
                                            record.raw_fields,
                                            PASS_THROUGH_FIELDS)
            add_organisationcode_testresult(genotype)
            add_provider_code(genotype, record, ORG_CODE_MAP)
            # binding.pry if record.mapped_fields['servicereportidentifier'] == 'W1800757'

            # For clarity, `raw_fields` contains multiple raw records for same SRI
            # record.raw_fields.each { |raw_record| process_raw_record(genotype, raw_record) }
            mol_testing_types = record.raw_fields.pluck('moleculartestingtype')&.uniq
            @mol_testing_type = mol_testing_types&.first&.downcase
            process_record(genotype, record)
          end

          def add_provider_code(genotype, record, org_code_map)
            raw_org = record.raw_fields.pluck('providercode')&.uniq&.first&.downcase
            org_code = org_code_map[raw_org]
            return if org_code.blank?

            genotype.attribute_map['providercode'] = org_code
          end

          def process_record(genotype, record)
            process_molecular_testing(genotype)
            genotypes = []
            if ROW_LEVEL.include?(@mol_testing_type)
              record.raw_fields.each { |raw_record| process_row_case(genotypes, genotype, raw_record) }
            elsif PANEL_LEVEL.keys.include?(@mol_testing_type)
              process_panel_case(genotypes, genotype, record)
            elsif HYBRID_LEVEL.include?(@mol_testing_type)
              process_hybrid_case(genotypes, genotype, record)
            end

            genotypes.each { |cur_genotype| @persister.integrate_and_store(cur_genotype) }
          end

          def process_row_case(genotypes, genotype, record)
            genotype_new = genotype.dup
            @status = record['status']&.downcase
            status = extract_teststatus_row_level
            genotype_new.add_status(status)
            extract_gene_row(genotype_new, record)
            if [2, 10].include? status
              assign_variantpathclass_row_level(genotype_new)
              variant = record['genotype']
              process_variants(genotype_new, variant) if positive_record?(genotype_new) && variant.present?
            end
            genotypes << genotype_new
          end

          def process_panel_case(genotypes, genotype, record)
            @all_genes = PANEL_LEVEL[@mol_testing_type]

            record.raw_fields.each do |raw_record|
              process_panel_record(genotypes, genotype, raw_record) unless @all_genes.empty?
            end

            # Mark rest of genes in panel as 1
            return if @all_genes.blank?

            process_status_genes(@all_genes, 1, genotype, genotypes, record)
          end

          def process_hybrid_case(genotypes, genotype, record)
            record.raw_fields.each do |raw_record|
              process_row_case(genotypes, genotype, raw_record)
            end

            # check if all genes covered
            genes_to_be_checked = HYBRID_LEVEL[@mol_testing_type]
            genes_processed = genotypes.each.collect { |a| a.attribute_map['gene'] }.uniq

            genes_to_be_added = genes_to_be_checked - genes_processed

            return if genes_to_be_added.blank?

            genes_to_be_added.each do |gene|
              genotype_new = genotype.dup
              genotype_new.add_gene(gene)
              genotype_new.add_status(1)
              genotypes << genotype_new
            end
          end

          def process_panel_record(genotypes, genotype, raw_record)
            @status = raw_record['status']&.downcase
            status_genes = []
            %w[test genotype].each do |field|
              result = raw_record[field]&.scan(BRCA_REGEX)&.flatten&.uniq
              if result.present?
                status_genes = result 
                break
              end
            end

            if UNKNOWN_STATUS.include? @status
              process_status_genes(@all_genes, 4, genotype, genotypes, raw_record)
            elsif FAILED_TEST.match(@status)
              process_status_genes(@all_genes, 9, genotype, genotypes, raw_record)
            elsif ABNORMAL_STATUS.include? @status
              process_status_genes(status_genes, 10, genotype, genotypes, raw_record)
            elsif NEGATIVE_STATUS.include? @status
              process_status_genes(@all_genes, 1, genotype, genotypes, raw_record)
            elsif POSITIVE_STATUS.include?(@status) || @status.match(/variant*/ix)
              process_status_genes(status_genes, 2, genotype, genotypes, raw_record)
            end
          end

          def process_status_genes(genes, status, genotype, genotypes, record)
            return unless genes&.all? { |gene| @all_genes.include?(gene) }

            genes.each do |gene|
              @all_genes -= [gene]
              genotype_new = genotype.dup
              genotype_new.add_gene(gene)
              genotype_new.add_status(status)
              if [2, 10].include? status
                assign_variantpathclass_row_level(genotype_new)
                variant = record['genotype']
                process_variants(genotype, variant) if positive_record?(genotype) && variant.present?
              end
              genotypes << genotype_new
            end
          end

          def process_molecular_testing(genotype)
            genotype.add_molecular_testing_type_strict(TEST_TYPE_MAPPING[@mol_testing_type])
            scope = TEST_SCOPE_MAPPING[@mol_testing_type].presence || :no_genetictestscope
            genotype.add_test_scope(scope)
          end

          def add_organisationcode_testresult(genotype)
            genotype.attribute_map['organisationcode_testresult'] = '699H0'
          end

          def extract_teststatus_row_level
            if POSITIVE_STATUS.include?(@status) || @status.match(/variant*/ix)
              2
            elsif NEGATIVE_STATUS.include?(@status)
              1
            elsif FAILED_TEST.match(@status)
              9
            elsif UNKNOWN_STATUS.include?(@status)
              4
            elsif ABNORMAL_STATUS.include? @status
              10
            end
          end

          def assign_variantpathclass_row_level(genotype)
            case @status
            when /like(ly)?\spathogenic/ix
              genotype.add_variant_class(4)
            when /pathogenic/ix
              genotype.add_variant_class(5)
            when /likely\sbenign/ix
              genotype.add_variant_class(2)
            when /benign/ix
              genotype.add_variant_class(1)
            when /variant/ix
              genotype.add_variant_class(3)
            end
          end

          def extract_gene_row(genotype, record)
            gene = []
            
            %w[test genotype moleculartestingtype].each do |field|
              result = record[field]&.scan(BRCA_REGEX)&.flatten&.uniq
              if result.present?
                gene = result
                break
              end
            end 

            binding.pry if gene.size > 1
            return if gene.blank?

            replacements = { 'BC1' => 'BRCA1', 'BC2' => 'BRCA2' }
            gene.map! { |g| replacements[g] || g }
            genotype.add_gene(gene.first)
          end

          def extract_teststatus(genotype, record)
            status = record.raw_fields['status']&.downcase
            geno_string = record.raw_fields['genotype']
            if POSITIVE_STATUS.include?(status)
              genotype.add_status(:positive)
            elsif NEGATIVE_STATUS.include?(status)
              genotype.add_status(:negative)
            elsif FAILED_TEST.match(@status)
              genotype.add_status(:failed)
            elsif UNKNOWN_STATUS.include?(status)
              genotype.add_status(:unknown)
            elsif GENO_DEPEND_STATUS.include?(status)
              teststatus = geno_string.blank? ? :negative : :positive
              genotype.add_status(teststatus)
            end
            @logger.debug "#{genotype.attribute_map['teststatus']} status for : #{status}"
          end

          def process_variants(genotype, variant)
            process_cdna_variant(genotype, variant)
            process_exonic_variant(genotype, variant)
            process_protein_impact(genotype, variant)
          end

          def process_exonic_variant(genotype, variant)
            return unless variant.scan(EXON_VARIANT_REGEX).size.positive?

            genotype.add_exon_location($LAST_MATCH_INFO[:exons])
            genotype.add_variant_type($LAST_MATCH_INFO[:mutationtype].to_s)
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

          def positive_record?(genotype)
            genotype.attribute_map['teststatus'] == 2
          end
        end
      end
    end
  end
end
