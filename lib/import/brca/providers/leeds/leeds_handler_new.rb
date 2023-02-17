require 'possibly'
require 'pry'

module Import
  module Brca
    module Providers
      module Leeds
        # Process Leeds-specific record details into generalized internal genotype format
        class LeedsHandlerNew < Import::Germline::ProviderHandler
          include Import::Helpers::Brca::Providers::Rr8::Constants

          def process_fields(record)
            populate_variables(record)
            return unless should_process(record)

            populate_genotype(record)
          end

          def populate_variables(record)
            @geno = (record.raw_fields['genotype'] || record.raw_fields['report_result'])&.downcase
            @report = record.raw_fields['report'] || record.raw_fields['firstofreport']
            @moleculartestingtype = (record.raw_fields['moleculartestingtype'] ||
                                    record.raw_fields['reason'])&.downcase
            @indicationcategory  = record.raw_fields['indicationcategory']&.downcase
            @genes_hash = YAML.safe_load(File.open(Rails.root.join(GENES_FILEPATH)))
            @status_hash = YAML.safe_load(File.open(Rails.root.join(STATUS_FILEPATH)))
          end

          def should_process(record)
            filename = @batch.original_filename.split('/').last
            return true if filename.scan(/BRCA/i).size.positive?
            return true if filename.scan(/other|familial/i).size.positive? &&
                           @indicationcategory == 'cancer' &&
                           @moleculartestingtype == 'familial' &&
                           (@geno&.scan(/BRCA/i)&.size&.positive? ||
                           @report&.scan(/BRCA1|BRCA2/i)&.size&.positive?)

            false
          end

          def populate_genotype(record)
            genotype = Import::Brca::Core::GenotypeBrca.new(record)
            genotype.add_passthrough_fields(record.mapped_fields, record.raw_fields,
                                            PASS_THROUGH_FIELDS)
            genotype.attribute_map['organisationcode_testresult'] = '699C0'
            add_moleculartestingtype(genotype, record)
            process_genetictestcope(genotype, record)
            assign_teststatus(genotype, record)
            res = process_variants_from_record(genotype, record)
            res.each { |cur_genotype| @persister.integrate_and_store(cur_genotype) }
          end

          def add_moleculartestingtype(genotype, _record)
            if @geno&.scan(/conf/i)&.size&.positive?
              genotype.add_molecular_testing_type_strict(:diagnostic)
            elsif @geno&.scan(/pred|unaff/i)&.size&.positive?
              genotype.add_molecular_testing_type_strict(:predictive)
            else
              genotype.add_molecular_testing_type_strict(TEST_TYPE_MAP[@moleculartestingtype])
            end
          end

          def process_genetictestcope(genotype, _record)
            if @geno&.scan(/AJ/i)&.size&.positive?
              genotype.add_test_scope(:aj_screen)
            else
              genotype.add_test_scope(TEST_SCOPE_MAP[@moleculartestingtype])
            end

            return unless genotype.attribute_map['genetictestscope'].nil?

            genotype.add_test_scope(:no_genetictestscope)
          end

          def assign_teststatus(genotype, _record)
            TEST_STATUS_MAPPINGS.each do |status, num_status|
              genotype.add_status(num_status) if @status_hash[status].include?(@geno)
            end
          end

          def process_variants_from_record(genotype, record)
            genotypes = []

            case genotype.attribute_map['teststatus']
            when 1
              process_normal_records(genotype, record, genotypes)
            when 9
              process_failed_records(genotype, record, genotypes)
            when 4, 8
              process_unknown_notested_records(genotype, record, genotypes)
            when 10
              process_normal_variant_records(genotype, record, genotypes)
            when 2
              process_abnormal_records(genotype, record, genotypes)
            end
            genotypes
          end

          def process_normal_records(genotype, _record, genotypes)
            allocate_genes_panel
            if genotype.targeted?
              norm_gene = TESTED_GENES_HASH[@geno]
              genes = norm_gene.nil? ? fetch_targ_gene : norm_gene
            else
              genes = @genes_panel
            end
            add_gene_info(genotype, genes, genotypes)
          end

          def process_failed_records(genotype, _record, genotypes)
            genes = if @geno == 'brca/palb2 diag screening failed'
                      %w[BRCA1 BRCA2 PALB2]
                    else
                      %w[BRCA1 BRCA2]
                    end
            add_gene_info(genotype, genes, genotypes)
          end

          def process_unknown_notested_records(genotype, _record, genotypes)
            if ['word report - abnormal',
                'not required'].include?(@geno)
              genes = %w[BRCA1 BRCA2]
            end
            add_gene_info(genotype, genes, genotypes)
          end

          def process_abnormal_records(genotype, record, genotypes)
            pos_genes = get_genes_report(@report)
            pos_genes = TESTED_GENES_HASH[@geno] if pos_genes.empty?
            allocate_variant_class
            allocate_genes_panel

            if pos_genes.nil?
              # create an abnormal GTR for rec without gene info
              genotype_dup = genotype.dup
              process_cdna_variant(genotype_dup, @report)
              process_exonic_variant(genotype_dup, @report)
              process_protein_impact(genotype_dup, @report)
              genotypes << genotype_dup
            elsif pos_genes.size > 1
              process_multi_gene_abnormal(genotype, record, genotypes)
            elsif pos_genes.size == 1
              process_single_gene_abnormal(genotype, genotypes, pos_genes)
            end
          end

          def process_normal_variant_records(genotype, _record, genotypes)
            genes = %w[BRCA1 BRCA2]
            report_variants = @report.match(VARIANT_REPORT_REGEX)[:report] unless @report.nil?
            gene_var = get_genes_report(report_variants)
            negative_genes = genes - gene_var
            process_negative_genes(negative_genes, genotype, genotypes)

            genotype_dup = genotype.dup
            process_cdna_variant(genotype_dup, @report)
            process_exonic_variant(genotype_dup, @report)
            process_protein_impact(genotype_dup, @report)
            genotype_dup.add_gene(gene_var[0])
            genotype_dup.add_variant_class(2)
            genotype_dup.add_status(10)
            genotypes << genotype_dup
          end

          def process_multi_gene_abnormal(genotype, _record, genotypes)
            return if @report.match(VARIANT_REPORT_REGEX).nil?

            report_variants = @report.match(VARIANT_REPORT_REGEX)[:report]
            pos_genes = get_genes_report(report_variants)

            if pos_genes.size > 1
              process_multi_pos_genes(genotype, report_variants, genotypes, pos_genes)
            else
              process_single_pos_gene(genotype, report_variants, genotypes, pos_genes)
            end
          end

          def process_single_gene_abnormal(genotype, genotypes, pos_genes)
            if genotype.full_screen? || genotype.ashkenazi?
              process_fs_ask_single_gene_abnormal(genotype, pos_genes, genotypes)
            else
              process_cdna_variant(genotype, @report)
              process_exonic_variant(genotype, @report)
              process_protein_impact(genotype, @report)
              genotype.add_variant_class(@variant_class)
              add_gene_info(genotype, pos_genes, genotypes)
            end
          end

          def process_multi_pos_genes(genotype, report_variants, genotypes, pos_genes)
            if report_variants.scan(CDNA_REGEX).size > 1
              process_multivariants(genotype, report_variants, genotypes)
              negative_genes = @genes_panel - pos_genes
            else
              negative_genes = process_single_variant(genotype, report_variants, genotypes)
            end
            process_negative_genes(negative_genes, genotype, genotypes)
          end

          def process_single_pos_gene(genotype, report_variants, genotypes, pos_genes)
            genotype_dup = genotype.dup
            process_cdna_variant(genotype_dup, report_variants)
            process_exonic_variant(genotype_dup, report_variants)
            process_protein_impact(genotype_dup, report_variants)
            genotype_dup.add_variant_class(@variant_class)
            genotype_dup.add_gene(pos_genes[0])
            genotypes << genotype_dup
            negative_genes = @genes_panel - pos_genes
            process_negative_genes(negative_genes, genotype, genotypes)
          end

          def process_multivariants(genotype, report_variants, genotypes)
            pos_genes = report_variants.scan(BRCA_REGEX).flatten.uniq
            mutations = report_variants.scan(CDNA_REGEX).flatten.uniq
            if mutations.size == pos_genes.size
              process_multivariant_zip(genotype, report_variants, genotypes, pos_genes, mutations)
            else
              process_multivariant_split(genotype, report_variants, genotypes, pos_genes)
            end
          end

          def process_multivariant_zip(genotype, report_variants, genotypes, pos_genes, mutations)
            proteins = report_variants.scan(PROTEIN_REGEX).flatten.uniq
            variants = pos_genes.zip(mutations, proteins)
            variants.each do |gene, mutation, protein|
              genotype_dup = genotype.dup
              genotype_dup.add_gene(gene)
              genotype_dup.add_gene_location(mutation)
              genotype_dup.add_protein_impact(protein)
              genotype_dup.add_variant_class(@variant_class)
              genotypes.append(genotype_dup)
            end
          end

          def process_multivariant_split(genotype, report_variants, genotypes, pos_genes)
            report_vars = report_variants.split(pos_genes[-1])
            report_vars[1].prepend(pos_genes[-1])
            report_vars.each do |rep|
              genotype_dup = genotype.dup
              process_cdna_variant(genotype_dup, rep)
              process_exonic_variant(genotype_dup, rep)
              process_protein_impact(genotype_dup, rep)
              genotype_dup.add_gene(rep.scan(BRCA_REGEX).flatten.uniq[0])
              genotypes.append(genotype_dup)
            end
          end

          def process_single_variant(genotype, report_variants, genotypes)
            genotype_dup = genotype.dup
            if ASSOC_GENE_REGEX.match(report_variants)
              genotype_dup.add_gene_location($LAST_MATCH_INFO[:cdna])
              genotype_dup.add_protein_impact($LAST_MATCH_INFO[:impact])
            elsif HETEROZYGOUS_GENE_REGEX.match(report_variants)
              # code from common block
            end
            pos_genes = $LAST_MATCH_INFO[:gene]
            genotype_dup.add_gene(pos_genes)
            genotype_dup.add_variant_class(@variant_class)
            genotypes << genotype_dup
            @genes_panel - [pos_genes]
          end

          def process_fs_ask_single_gene_abnormal(genotype, pos_gene, genotypes)
            @genes_panel = %w[BRCA1 BRCA2] if genotype.ashkenazi?

            negative_genes = @genes_panel - pos_gene

            process_negative_genes(negative_genes, genotype, genotypes)

            process_cdna_variant(genotype, @report)
            process_exonic_variant(genotype, @report)
            process_protein_impact(genotype, @report)
            genotype.add_variant_class(@variant_class)
            add_gene_info(genotype, pos_gene, genotypes)
          end

          def allocate_genes_panel
            @genes_panel = get_genes_report(@report)

            return unless @genes_panel.empty? || @genes_panel.size == 1 ||
                          @report.scan(/panel/i).size.positive? || @geno == 'normal b1 and b2'

            GENES_PANEL.each do |panel_name, genes_panel|
              @genes_panel = genes_panel if @genes_hash[panel_name].include?(@geno)
            end
          end

          def get_genes_report(report)
            genes = report.scan(BRCA_REGEX).flatten.uniq unless @report.nil?
            genes -= ['Met'] if @report.scan(/p\.\(?\w*Met/).size.positive?
            genes
          end

          def fetch_targ_gene
            @report.match(TARG_GENE_REGEX) || @report.match(BRCA_REGEX)
            [$LAST_MATCH_INFO[:gene]]
          end

          def allocate_variant_class
            return if @geno.scan(%r{C\d/C\d|C\d/\d}ix).size.positive?

            @variant_class = if @geno.scan(/C3|Class\s3/ix).size.positive?
                               3
                             elsif @geno.scan(/C4|Class\s4/ix).size.positive?
                               4
                             elsif @geno.scan(/C5|Class\s5/ix).size.positive? ||
                                   VARIANT_CLASS_5.include?(@geno)
                               5
                             end
          end

          def process_negative_genes(negative_genes, genotype, genotypes)
            negative_genes&.each do |gene|
              genotype_dup = genotype.dup
              genotype_dup.add_gene(gene)
              genotype_dup.add_status(1)
              genotypes << genotype_dup
            end
          end

          def add_gene_info(genotype, genes, genotypes)
            genes&.each do |gene|
              genotype_dup = genotype.dup
              genotype_dup.add_gene(gene)
              genotypes << genotype_dup
            end
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
        end
      end
    end
  end
end
