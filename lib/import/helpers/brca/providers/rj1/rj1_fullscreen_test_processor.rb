module Import
  module Helpers
    module Brca
      module Providers
        module Rj1
          # Processor for Full Screen Tests exctraction methods
          # rubocop:disable Metrics/ModuleLength
          module Rj1FullscreenTestProcessor
            include Import::Helpers::Brca::Providers::Rj1::Rj1Constants

            #####################################################################################
            ################ HERE ARE FULL SCREEN TESTS #########################################
            #####################################################################################

            def all_fullscreen_option2_relevant_fields_nil?
              @brca1_mlpa_result.nil? && @brca2_mlpa_result.nil? &&
                @brca1_mutation.nil? && @brca2_mutation.nil? &&
                @brca1_seq_result.nil? && @brca2_seq_result.nil?
            end

            def double_brca_mlpa_negative?
              return false if @brca1_mlpa_result.nil? || @brca2_mlpa_result.nil?

              no_brca1_cdna_variant? && no_brca2_cdna_variant? &&
                @brca1_mlpa_result.scan(%r{no\sdel/dup}i).size.positive? &&
                @brca2_mlpa_result.scan(%r{no\sdel/dup}i).size.positive?
            end

            def all_null_cdna_variants_except_full_screen_test?
              return false if @fullscreen_result.nil?

              no_brca1_cdna_variant? && no_brca2_cdna_variant?
            end

            def no_brca1_cdna_variant?
              (@brca1_seq_result.nil? ||
              @brca1_seq_result.downcase == 'normal' ||
              @brca1_seq_result.scan(CDNA_REGEX).size.zero?) && @brca1_mutation.nil?
            end

            def no_brca2_cdna_variant?
              (@brca2_seq_result.nil? ||
              @brca2_seq_result.downcase == 'normal' ||
              @brca2_seq_result.scan(CDNA_REGEX).size.zero?) && @brca2_mutation.nil?
            end

            # rubocop:disable Style/GuardClause
            # Disabled this complaint as I need the method as it is. Changing it would change result
            def process_fullscreen_result_cdnavariant
              return if @fullscreen_result.nil?

              detected_genes = process_detected_genes
              split_records = create_split_records(detected_genes)
              positive_genes = process_positive_genes(split_records)
              process_split_records(split_records)
              negative_gene = %w[BRCA1 BRCA2] - positive_genes
              if negative_gene.present?
                process_negative_or_failed_gene(negative_gene.join,
                                                1, :full_screen)
              end
            end
            # rubocop:enable Style/GuardClause

            def create_split_records(detected_genes)
              split_records = @fullscreen_result.split(detected_genes[-1])
              split_records[1].prepend(detected_genes[-1])
              split_records.map! do |split_record|
                split_record.gsub('B1', 'BRCA1').gsub('B2', 'BRCA2')
              end
              split_records = split_records.reject(&:empty?)
              if split_records.size > split_records.join.scan(BRCA_GENES_REGEX).flatten.size
                split_records[-1] = split_records[-1].sub(' ', "#{detected_genes[-1]} ")
              end
              split_records
            end

            def process_positive_genes(split_records)
              if split_records.is_a? String
                split_records.scan(/(?<brca>BRCA1|BRCA2)/i).flatten.uniq.compact
              else
                split_records.join.scan(/(?<brca>BRCA1|BRCA2)/i).flatten.uniq.compact
              end
            end

            def process_detected_genes
              if @fullscreen_result.scan(/(?<brca>BRCA1|BRCA2)/i).present?
                @fullscreen_result.scan(/(?<brca>BRCA1|BRCA2)/i).flatten.compact.uniq
              else
                @fullscreen_result.scan(DEPRECATED_BRCA_NAMES_REGEX).flatten.compact.uniq
              end
            end

            def process_split_records(split_records)
              if split_records.is_a? String
                process_positive_cdnavariant(positive_genes.join, @fullscreen_result, :full_screen)
              else
                split_records.each do |list_of_variants|
                  next if list_of_variants.scan(/(?<brca>BRCA1|BRCA2)/i).empty?

                  process_list_of_variants_splitrecords(list_of_variants)
                end
              end
              @genotypes
            end

            def process_list_of_variants_splitrecords(list_of_variants)
              gene = list_of_variants.match(/(?<brca>BRCA1|BRCA2)/i)[:brca]
              cdnavariants = list_of_variants.scan(CDNA_REGEX).uniq.flatten.compact
              genes = [gene] * cdnavariants.uniq.size
              genes.zip(cdnavariants.uniq).each do |brca, variant|
                positive_genotype = @genotype.dup
                positive_genotype.add_gene(brca)
                positive_genotype.add_gene_location(variant)
                positive_genotype.add_status(2)
                positive_genotype.add_test_scope(:full_screen)
                @genotypes.append(positive_genotype)
              end
            end

            def brca1_seq_result_missing_cdot?
              return false if @brca1_seq_result.nil?

              @brca1_seq_result.scan(/(?<cdna>[0-9]+[a-z]+>[a-z]+)/i).size.positive?
            end

            def brca2_seq_result_missing_cdot?
              return false if @brca2_seq_result.nil?

              @brca2_seq_result.scan(/(?<cdna>[0-9]+[a-z]+>[a-z]+)/i).size.positive?
            end

            def fullscreen_brca2_mutated_cdna_brca1_normal?
              @ngs_result.scan(/B2|BRCA2|BRCA 2|BR2/i).size.positive? &&
                @ngs_result.scan(CDNA_REGEX).size.positive?
            end

            def process_fullscreen_brca2_mutated_cdna_brca1_normal(cdna_variant)
              process_negative_or_failed_gene('BRCA1', 1, :full_screen)
              process_positive_cdnavariant('BRCA2', cdna_variant, :full_screen)
              @genotypes
            end

            def fullscreen_brca1_mutated_cdna_brca2_normal?
              @ngs_result.scan(/B1|BRCA1|BRCA 1|BR1/i).size.positive? &&
                @ngs_result.scan(CDNA_REGEX).size.positive?
            end

            def process_fullscreen_brca1_mutated_cdna_brca2_normal(cdna_variant)
              process_negative_or_failed_gene('BRCA2', 1, :full_screen)
              process_positive_cdnavariant('BRCA1', cdna_variant, :full_screen)
              @genotypes
            end

            def fullscreen_brca2_mutated_exon_brca1_normal?
              (@ngs_result.scan(/B2|BRCA2|BRCA 2|BR2/i).size.positive? &&
              @ngs_result.scan(EXON_REGEX).size.positive?) ||
                (@brca2_mlpa_result.present? && @brca2_mlpa_result.scan(EXON_REGEX).size.positive?)
            end

            def process_fullscreen_brca2_mutated_exon_brca1_normal(exon_variant)
              process_negative_or_failed_gene('BRCA1', 1, :full_screen)
              process_positive_exonvariant('BRCA2', exon_variant, :full_screen)
              @genotypes
            end

            def process_fullscreen_nonbrca_mutated_exon(exon_variant)
              process_double_brca_status(1, :full_screen)
              process_positive_exonvariant(@ngs_result.match(BRCA_GENES_REGEX)[:brca],
                                           exon_variant, :full_screen)
              @genotypes
            end

            def fullscreen_brca1_mutated_exon_brca2_normal?
              (@ngs_result.scan(/B1|BRCA1|BRCA 1|BR1/i).size.positive? &&
              @ngs_result.scan(EXON_REGEX).size.positive?) ||
                (@brca1_mlpa_result.present? && @brca1_mlpa_result.scan(EXON_REGEX).size.positive?)
            end

            def process_fullscreen_brca1_mutated_exon_brca2_normal(exon_variant)
              process_negative_or_failed_gene('BRCA2', 1, :full_screen)
              # exon_variant = @ngs_result.match(EXON_REGEX)
              process_positive_exonvariant('BRCA1', exon_variant, :full_screen)
              @genotypes
            end

            def process_adhoc_chek2_fullscreen_positive_records
              process_double_brca_status(1, :full_screen)
              positive_genotype = @genotype.dup
              positive_genotype.add_gene('CHEK2')
              positive_genotype.add_gene_location('1100delC')
              positive_genotype.add_status(2)
              positive_genotype.add_test_scope(:full_screen)
              @genotypes.append(positive_genotype)
            end

            def fullscreen_non_brca_mutated_cdna_gene?
              return false if @ngs_result.nil?

              (@ngs_result.scan(/(?<nonbrca>CHEK2|PALB2|TP53)/i).size.positive? &&
                @ngs_result.scan(CDNA_REGEX).size.positive?) ||
                (@fullscreen_result.present? &&
                @fullscreen_result.scan(/(?<nonbrca>CHEK2|PALB2|TP53)/i).size.positive? &&
                @fullscreen_result.scan(CDNA_REGEX).size.positive?)
            end

            def fullscreen_non_brca_mutated_exon_gene?
              return false if @ngs_result.nil?

              @ngs_result.scan(/(?<nonbrca>CHEK2|PALB2|TP53)/i).size.positive? &&
                @ngs_result.scan(EXON_REGEX).size.positive?
            end

            def process_fullscreen_non_brca_mutated_cdna_gene
              return false if @ngs_result.nil?

              process_double_brca_status(1, :full_screen)
              positive_gene = @ngs_result.match(/(?<nonbrca>CHEK2|PALB2|TP53)/i)[:nonbrca]
              process_positive_cdnavariant(positive_gene, @ngs_result, :full_screen)
              @genotypes
            end

            def process_fullscreen_non_brca_mutated_exon_gene
              return if @ngs_result.nil?

              process_double_brca_status(1, :full_screen)
              positive_gene = @ngs_result.match(/(?<nonbrca>CHEK2|PALB2|TP53)/i)[:nonbrca]
              process_positive_exonvariant(positive_gene, @ngs_result.match(EXON_REGEX),
                                           :full_screen)
              @genotypes
            end

            def add_full_screen_date_option1
              return if @ngs_report_date.nil?

              @genotype.attribute_map['authoriseddate'] = @ngs_report_date
            end

            def add_full_screen_date_option2
              return if @authoriseddate.nil?

              @genotype.attribute_map['authoriseddate'] = @authoriseddate
            end

            def add_full_screen_date_option3
              return if @date_2_3_reported.nil? && @brca1_report_date.nil? &&
                        @brca2_report_date.nil? && @brca2_ptt_report_dated.nil? &&
                        @full_ppt_report_date.nil?

              date = [
                @date_2_3_reported, @brca1_report_date, @brca2_report_date,
                @brca2_ptt_report_dated, @full_ppt_report_date
              ].compact
              @genotype.attribute_map['authoriseddate'] = if date.size > 1
                                                            date.min
                                                          else
                                                            date.join
                                                          end
            end

            def brca_false_positives?
              return false if @brca1_seq_result.nil? && @brca2_seq_result.nil?

              (@brca1_seq_result.present? && @brca1_seq_result.scan(/-ve/i).size.positive? &&
              [@brca2_mutation, @brca2_seq_result].uniq.compact.empty?) ||
                (@brca2_seq_result.present? && @brca2_seq_result.scan(/-ve/i).size.positive? &&
                [@brca1_mutation, @brca1_seq_result].uniq.compact.empty?)
            end

            def brca1_cdna_variant_fullscreen_option3?
              return false if @brca1_mutation.nil? && @brca1_seq_result.nil?

              ((@brca1_mutation.present? && @brca1_mutation.scan(CDNA_REGEX).size.positive?) ||
              (@brca1_seq_result.present? && @brca1_seq_result.scan(CDNA_REGEX).size.positive?))
            end

            def process_brca1_cdna_variant_fullscreen_option3
              cdna_variant = [@brca1_mutation, @brca1_seq_result].flatten.uniq.join
              if [@brca2_mutation, @brca2_seq_result].flatten.compact.uniq.empty? ||
                 [@brca2_mutation, @brca2_seq_result].join.scan(/neg|norm|-ve/i).size.positive?
                process_fullscreen_brca1_mutated_cdna_brca2_normal(cdna_variant)
              end
              @genotypes
            end

            def brca2_cdna_variant_fullscreen_option3?
              return false if @brca2_mutation.nil? && @brca2_seq_result.nil?

              ((@brca2_mutation.present? && @brca2_mutation.scan(CDNA_REGEX).size.positive?) ||
              (@brca2_seq_result.present? && @brca2_seq_result.scan(CDNA_REGEX).size.positive?))
            end

            def process_brca2_cdna_variant_fullscreen_option3
              cdna_variant = [@brca2_mutation, @brca2_seq_result].flatten.uniq.join
              if [@brca1_mutation, @brca1_seq_result].flatten.compact.uniq.empty?
                process_fullscreen_brca2_mutated_cdna_brca1_normal(cdna_variant)
              end
              @genotypes
            end

            def brca1_malformed_cdna_fullscreen_option3?
              ((@brca1_mutation.present? && @brca1_mutation.scan(CDNA_REGEX).size.zero?) ||
              (@brca1_seq_result.present? && @brca1_seq_result.scan(CDNA_REGEX).size.zero?)) &&
                (@brca2_mutation.nil? && @brca2_seq_result.nil? &&
                @brca1_mlpa_result.nil? && @brca2_mlpa_result.nil?)
            end

            def double_brca_malformed_cdna_fullscreen_option3?
              ((@brca1_mutation.present? && @brca1_mutation.scan(CDNA_REGEX).size.zero?) ||
              (@brca1_seq_result.present? && @brca1_seq_result.scan(CDNA_REGEX).size.zero?)) &&
                ((@brca2_mutation.present? && @brca2_mutation.scan(CDNA_REGEX).size.zero?) ||
                (@brca2_seq_result.present? && @brca2_seq_result.scan(CDNA_REGEX).size.zero?))
            end

            def process_double_brca_malformed_cdna_fullscreen_option3
              process_malformed_brca1_cdna_fullscreen
              process_malformed_brca2_cdna_fullscreen
            end

            def process_malformed_brca2_cdna_fullscreen
              badformat_cdna_brca2_variant = if @brca2_seq_result.present?
                                               @brca2_seq_result.scan(/([^\s]+)\s?/i)[0].join
                                             else
                                               @brca2_mutation.scan(/([^\s]+)\s?/i)[0].join
                                             end
              positive_genotype = @genotype.dup
              positive_genotype.add_gene('BRCA2')
              positive_genotype.add_gene_location(badformat_cdna_brca2_variant.tr(';', ''))
              positive_genotype.add_status(2)
              positive_genotype.add_test_scope(:full_screen)
              @genotypes.append(positive_genotype)
            end

            def process_malformed_brca1_cdna_fullscreen
              badformat_cdna_brca1_variant = if @brca1_seq_result.present?
                                               @brca1_seq_result.scan(/([^\s]+)\s?/i)[0].join
                                             else
                                               @brca1_mutation.scan(/([^\s]+)\s?/i)[0].join
                                             end
              positive_genotype = @genotype.dup
              positive_genotype.add_gene('BRCA1')
              positive_genotype.add_gene_location(badformat_cdna_brca1_variant.tr(';', ''))
              positive_genotype.add_status(2)
              positive_genotype.add_test_scope(:full_screen)
              @genotypes.append(positive_genotype)
            end

            def process_brca1_malformed_cdna_fullscreen_option3
              return if @brca1_seq_result.nil? && @brca1_mutation.nil?

              process_negative_or_failed_gene('BRCA2', 1, :full_screen)
              process_malformed_brca1_cdna_fullscreen
            end

            def brca2_malformed_cdna_fullscreen_option3?
              ((@brca2_mutation.present? && @brca2_mutation.scan(CDNA_REGEX).size.zero?) ||
              (@brca2_seq_result.present? && @brca2_seq_result.scan(CDNA_REGEX).size.zero?)) &&
                @brca1_mutation.nil? && @brca1_seq_result.nil? &&
                @brca1_mlpa_result.nil? && @brca2_mlpa_result.nil?
            end

            def normal_brca2_malformed_fullscreen_option3?
              return false if @brca2_seq_result.nil?

              @brca2_seq_result.scan(/neg|norm/i).size.positive?
            end

            # rubocop:disable Metrics/AbcSize
            def process_brca2_malformed_cdna_fullscreen_option3
              return if (@brca2_seq_result.nil? && @brca2_mutation.nil?) ||
                        (@brca2_seq_result.present? &&
                         @brca2_seq_result.scan(/neg|norm/i).size.positive?)

              process_negative_or_failed_gene('BRCA1', 1, :full_screen)

              if @brca2_seq_result.present? && @brca2_seq_result.scan(/neg|norm/i).size.zero?
                badformat_cdna_brca2_variant = @brca2_seq_result.scan(/([^\s]+)/i)[0].join
              else
                badformat_cdna_brca2_variant = @brca2_mutation.scan(/([^\s]+)/i)[0].join
              end
              positive_genotype = @genotype.dup
              positive_genotype.add_gene('BRCA2')
              positive_genotype.add_gene_location(badformat_cdna_brca2_variant.tr(';', ''))
              positive_genotype.add_status(2)
              positive_genotype.add_test_scope(:full_screen)
              @genotypes.append(positive_genotype)
            end
            # rubocop:enable Metrics/AbcSize

            def fullscreen_brca1_mlpa_positive_variant?
              return false if @brca1_mlpa_result.nil?

              @brca1_mlpa_result.scan(EXON_REGEX).size.positive?
            end

            def process_full_screen_brca1_mlpa_positive_variant(exon_variant)
              process_negative_or_failed_gene('BRCA2', 1, :full_screen)
              process_positive_exonvariant('BRCA1', exon_variant, :full_screen)
              @genotypes
            end

            def fullscreen_brca2_mlpa_positive_variant?
              return false if @brca2_mlpa_result.nil?

              @brca2_mlpa_result.scan(EXON_REGEX).size.positive?
            end

            def process_full_screen_brca2_mlpa_positive_variant(exon_variant)
              process_negative_or_failed_gene('BRCA1', 1, :full_screen)
              process_positive_exonvariant('BRCA2', exon_variant, :full_screen)
              @genotypes
            end

            def fullscreen_normal_double_brca_mlpa_option2?
              return false if @brca1_mlpa_result.nil? && @brca2_mlpa_result.nil?

              @brca1_mlpa_result.scan(%r{no del/dup}i).size.positive? &&
                @brca2_mlpa_result.scan(%r{no del/dup}i).size.positive?
            end

            def brca2_cdna_variant_fullscreen_option2?
              (!@brca2_mutation.nil? && @brca2_mutation.scan(CDNA_REGEX).size.positive?) ||
                (!@brca2_seq_result.nil? && @brca2_seq_result.scan(CDNA_REGEX).size.positive?)
            end

            def process_fullscreen_brca2_mutated_cdna_option2
              process_negative_or_failed_gene('BRCA1', 1, :full_screen)
              if !@brca2_mutation.nil? && @brca2_mutation.scan(CDNA_REGEX).size.positive?
                process_positive_cdnavariant('BRCA2', @brca2_mutation, :full_screen)
              elsif !@brca2_seq_result.nil? && @brca2_seq_result.scan(CDNA_REGEX).size.positive?
                process_positive_cdnavariant('BRCA2', @brca2_seq_result, :full_screen)
              end
              @genotypes
            end

            def process_malformed_variants_fullscreen_option1
              positive_genotype = @genotype.dup
              positive_gene = @ngs_result.scan(BRCA_GENES_REGEX).flatten.compact.join
              negative_gene = %w[BRCA2
                                 BRCA1] - @ngs_result.scan(BRCA_GENES_REGEX).flatten.compact
              process_negative_or_failed_gene(negative_gene.join, 1, :full_screen)
              positive_genotype.add_gene(positive_gene)
              positive_genotype.add_gene_location(
                @ngs_result.match(/(?<cdna>[0-9]+[a-z]+>[a-z]+)/i)[:cdna].tr(
                  ';', ''
                )
              )
              positive_genotype.add_status(2)
              positive_genotype.add_test_scope(:full_screen)
              @genotypes.append(positive_genotype)
            end

            def brca1_cdna_variant_fullscreen_option2?
              (!@brca1_mutation.nil? && @brca1_mutation.scan(CDNA_REGEX).size.positive?) ||
                (!@brca1_seq_result.nil? && @brca1_seq_result.scan(CDNA_REGEX).size.positive?)
            end

            def brca1_normal_brca2_nil?
              (@brca2_mutation.nil? && @brca2_seq_result.nil? && @brca2_mlpa_result.nil?) &&
                ((@brca1_mlpa_result.present? &&
                @brca1_mlpa_result.scan(%r{no del/dup}i).size.positive?) ||
                (@brca1_seq_result.present? && @brca1_seq_result.scan(/neg|norm/i).size.positive?))
            end

            def brca2_normal_brca1_nil?
              (@brca1_mutation.nil? && @brca1_seq_result.nil? && @brca1_mlpa_result.nil?) &&
                ((@brca2_mlpa_result.present? &&
                @brca2_mlpa_result.scan(%r{no del/dup}i).size.positive?) ||
                (@brca2_seq_result.present? && @brca2_seq_result.scan(/neg|norm/i).size.positive?))
            end

            def process_deprecated_genes_record_fullscreen_option1
              variants = @ngs_result.scan(CDNA_REGEX).uniq.flatten.compact
              tested_genes = @ngs_result.scan(DEPRECATED_BRCA_NAMES_REGEX).flatten.uniq.
                             flatten.compact
              positive_genes = tested_genes.map do |tested_gene|
                DEPRECATED_BRCA_NAMES_MAP[tested_gene]
              end
              process_multiple_variants_fullscreen_results(variants, positive_genes)
            end

            def brca1_mlpa_nil_brca2_mlpa_normal?
              @brca1_mlpa_result.nil? && @brca2_mlpa_result&.scan(%r{no del/dup}i)&.size&.positive?
            end

            def brca2_mlpa_nil_brca1_mlpa_normal?
              @brca2_mlpa_result.nil? && @brca1_mlpa_result&.scan(%r{no del/dup}i)&.size&.positive?
            end

            def brca2_mlpa_na_brca1_mlpa_normal?
              @brca2_mlpa_result&.downcase == 'n/a' &&
                @brca1_mlpa_result&.scan(%r{no del/dup}i)&.size&.positive?
            end

            def brca1_mlpa_na_brca2_mlpa_normal?
              @brca1_mlpa_result&.downcase == 'n/a' &&
                @brca2_mlpa_result&.scan(%r{no del/dup}i)&.size&.positive?
            end

            def brca12_mlpa_normal_brca12_null?
              return false if @brca2_mlpa_result.nil? && @brca1_mlpa_result.nil?

              brca1_mlpa_nil_brca2_mlpa_normal? ||
                brca2_mlpa_nil_brca1_mlpa_normal? ||
                brca2_mlpa_na_brca1_mlpa_normal? ||
                brca1_mlpa_na_brca2_mlpa_normal?
            end

            def process_multiple_variants_fullscreen_results(variants, genes)
              negative_gene = %w[BRCA1 BRCA2] - genes
              if negative_gene.present?
                process_negative_or_failed_gene(negative_gene.join,
                                                1, :full_screen)
              end
              if genes.uniq.size == variants.uniq.size
                process_even_gene_cdna_variants_fullscreen_fullscreenresults(genes, variants)
              else
                genes = genes.uniq * variants.uniq.size
                process_one_gene_many_cdna_variants_fullscreen_fullscreenresults(genes, variants)
              end
              @genotypes
            end

            def process_even_gene_cdna_variants_fullscreen_fullscreenresults(genes, variants)
              genes.zip(variants).each do |gene, variant|
                positive_genotype = @genotype.dup
                positive_genotype.add_gene(gene)
                positive_genotype.add_gene_location(variant)
                positive_genotype.add_status(2)
                positive_genotype.add_test_scope(:full_screen)
                @genotypes.append(positive_genotype)
              end
            end

            def process_one_gene_many_cdna_variants_fullscreen_fullscreenresults(genes, variants)
              genes.zip(variants.uniq).each do |gene, variant|
                positive_genotype = @genotype.dup
                positive_genotype.add_gene(gene)
                positive_genotype.add_gene_location(variant)
                positive_genotype.add_status(2)
                positive_genotype.add_test_scope(:full_screen)
                @genotypes.append(positive_genotype)
              end
            end

            def process_fullscreen_brca1_mutated_cdna_option2
              process_negative_or_failed_gene('BRCA2', 1, :full_screen)
              if !@brca1_mutation.nil? && @brca1_mutation.scan(CDNA_REGEX).size.positive?
                process_positive_cdnavariant('BRCA1', @brca1_mutation, :full_screen)
              elsif !@brca1_seq_result.nil? && @brca1_seq_result.scan(CDNA_REGEX).size.positive?
                process_positive_cdnavariant('BRCA1', @brca1_seq_result, :full_screen)
              end
              @genotypes
            end
          end
          # rubocop:enable Metrics/ModuleLength
        end
      end
    end
  end
end
