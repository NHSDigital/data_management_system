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
            record.raw_fields.reject! do |raw_record|
              raw_record['status'].match(/Variant\sfor\sAlissa\sreview/ix)
            end

            # For clarity, `raw_fields` contains multiple raw records for same SRI
            assign_molecular_testing_var(record)
            res = process_record(genotype, record)
            res.each { |cur_genotype| @persister.integrate_and_store(cur_genotype) }
          end

          def assign_molecular_testing_var(record)
            @mol_testing_type = record.raw_fields.pluck('moleculartestingtype')&.uniq&.first&.downcase
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

            genotypes
          end

          def process_row_case(genotypes, genotype, record)
            genotype_new = genotype.dup
            assign_status_var(record)
            status = extract_teststatus_record
            genotype_new.add_status(status)
            extract_gene_row(genotype_new, record)
            if [2, 10].include? status
              handle_variant_record(genotype_new, record, genotypes)
            else
              genotypes << genotype_new
            end
            genotypes
          end

          def process_panel_case(genotypes, genotype, record)
            @all_genes = PANEL_LEVEL[@mol_testing_type]
            @status_genes_hash = {}

            prepare_gene_status_hash(record)

            record.raw_fields.each do |raw_record|
              assign_status_var(raw_record)
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
            genes_to_be_present = HYBRID_LEVEL[@mol_testing_type]
            genes_processed = genotypes.each.collect { |a| a.attribute_map['gene'] }.uniq

            genes_to_be_added = genes_to_be_present - genes_processed

            return if genes_to_be_added.blank?

            genes_to_be_added.each do |gene|
              genotype_new = genotype.dup
              genotype_new.add_gene(gene)
              genotype_new.add_status(1)
              genotypes << genotype_new
            end
          end

          def process_panel_record(genotypes, genotype, raw_record)
            status_genes = extract_genes(%w[test genotype], raw_record)
            status_genes.each do |status_gene|
              status_found = @status_genes_hash[status_gene]&.uniq
              if status_found.size > 1
                process_multi_status_genes([status_gene], status_found, genotype, genotypes, raw_record)
              elsif UNKNOWN_STATUS.include? @status
                process_status_genes([status_gene], 4, genotype, genotypes, raw_record)
              elsif FAILED_TEST.match(@status)
                process_status_genes(@all_genes, 9, genotype, genotypes, raw_record)
              elsif ABNORMAL_STATUS.include? @status
                process_status_genes([status_gene], 10, genotype, genotypes, raw_record)
              elsif NEGATIVE_STATUS.include? @status
                process_status_genes([status_gene], 1, genotype, genotypes, raw_record)
              elsif POSITIVE_STATUS.include?(@status) || @status.match(/^variant*/ix)
                process_status_genes([status_gene], 2, genotype, genotypes, raw_record)
              end
            end
          end

          def prepare_gene_status_hash(record)
            record.raw_fields.each do |raw_record|
              assign_status_var(raw_record)

              status_genes = extract_genes(%w[test genotype], raw_record)
              status_genes.each do |status_gene|
                if @status_genes_hash[status_gene]
                  @status_genes_hash[status_gene] << @status
                else
                  @status_genes_hash[status_gene] = [@status]
                end
              end
            end
          end

          def extract_genes(fields, raw_record)
            status_genes = []
            fields.each do |field|
              result = raw_record[field]&.scan(BRCA_REGEX)&.flatten&.uniq
              if result.present?
                status_genes = result
                break
              end
            end
            status_genes
          end

          def assign_status_var(raw_record)
            @status = raw_record['status']&.downcase
          end

          # Use priority if more than one status is present for same gene for a given record
          # rubocop:disable Metrics/CyclomaticComplexity, Metrics/AbcSize, Metrics/PerceivedComplexity
          def process_multi_status_genes(status_genes, status_found, genotype, genotypes, raw_record)
            if status_found.intersect?(POSITIVE_STATUS) || status_found.any? { |e| e.match(/^variant/) }
              process_status_genes(status_genes, 2, genotype, genotypes, raw_record) if extract_teststatus_record == 2
            elsif status_found.intersect?(ABNORMAL_STATUS)
              process_status_genes(status_genes, 10, genotype, genotypes, raw_record) if extract_teststatus_record == 10
            elsif status_found.intersect?(NEGATIVE_STATUS)
              process_status_genes(status_genes, 1, genotype, genotypes, raw_record) if extract_teststatus_record == 1
            elsif status_found.match(FAILED_TEST)
              process_status_genes(@all_genes, 9, genotype, genotypes, raw_record) if extract_teststatus_record == 9
            elsif status_found.intersect?(UNKNOWN_STATUS)
              process_status_genes(status_genes, 4, genotype, genotypes, raw_record) if extract_teststatus_record == 4
            end
          end
          # rubocop:enable Metrics/CyclomaticComplexity, Metrics/AbcSize, Metrics/PerceivedComplexity

          def process_status_genes(genes, status, genotype, genotypes, record)
            return unless genes&.all? { |gene| @all_genes.include?(gene) }

            genes.each do |gene|
              @all_genes -= [gene]
              genotype_new = genotype.dup
              genotype_new.add_gene(gene)
              genotype_new.add_status(status)
              if [2, 10].include? status
                handle_variant_record(genotype_new, record, genotypes)
              else
                genotypes << genotype_new
              end
            end
            genotypes
          end

          def handle_variant_record(genotype_new, record, genotypes)
            assign_variantpathclass_record(genotype_new)
            variant = record['genotype']
            if variant.present?
              if variant.scan(CDNA_REGEX).size > 1 ||
                 variant.scan(EXON_VARIANT_REGEX).size > 1
                process_multi_vars(genotype_new, variant, genotypes)
              else
                process_variants(genotype_new, variant, genotypes)
              end
            else
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

          def extract_teststatus_record
            if POSITIVE_STATUS.include?(@status) || @status.match(/^variant*/ix)
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

          def assign_variantpathclass_record(genotype)
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
            gene = extract_genes(%w[test genotype moleculartestingtype], record)
            return if gene.blank?

            replacements = { 'BC1' => 'BRCA1', 'BC2' => 'BRCA2' }
            gene.map! { |g| replacements[g] || g }
            genotype.add_gene(gene.first)
          end

          def process_multi_vars(genotype_new, variant, genotypes)
            variants = variant.split(/;|,/)
            variants.each do |var|
              genotype_dup = genotype_new.dup
              gene = var&.scan(BRCA_REGEX)&.flatten&.uniq
              if gene.present?
                genotype_dup.add_gene(gene[0])
                @all_genes -= gene if @all_genes.present?
              end
              process_variants(genotype_dup, var, genotypes)
            end
          end

          def process_variants(genotype_new, variant, genotypes)
            process_cdna_variant(genotype_new, variant)
            process_exonic_variant(genotype_new, variant)
            process_protein_impact(genotype_new, variant)
            genotypes << genotype_new
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
        end
      end
    end
  end
end
