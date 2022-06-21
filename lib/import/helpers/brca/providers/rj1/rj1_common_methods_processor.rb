module Import
  module Helpers
    module Brca
      module Providers
        module Rj1
          # Processor for common exctraction methods for FullScreen, Targeted, Ashkenazi and Polish
          module Rj1CommonMethodsProcessor
            include Import::Helpers::Brca::Providers::Rj1::Rj1Constants

            #####################################################################################
            ################ HERE ARE COMMON METHODS ############################################
            #####################################################################################

            # rubocop:disable Metrics/CyclomaticComplexity
            def no_cdna_variant?
              return if @brca1_mlpa_result.nil? && @brca2_mlpa_result.nil?

              @brca1_mutation.nil? && @brca2_mutation.nil? &&
                @brca1_seq_result.nil? && @brca2_seq_result.nil? &&
                @brca1_mlpa_result&.downcase == 'n/a' && @brca2_mlpa_result&.downcase == 'n/a'
            end
            # rubocop:enable Metrics/CyclomaticComplexity

            def brca1_mutation?
              return if @brca1_mutation.nil?

              @brca1_mutation.scan(CDNA_REGEX).size.positive?
            end

            def brca2_mutation?
              return if @brca2_mutation.nil?

              @brca2_mutation.scan(CDNA_REGEX).size.positive?
            end

            def normal_brca1_seq?
              return if @brca1_seq_result.nil?

              @brca1_seq_result.downcase == '-ve' ||
                @brca1_seq_result.downcase == 'neg' ||
                @brca1_seq_result.downcase == 'nrg' ||
                @brca1_seq_result.scan(/neg|nrg|norm|-ve/i).size.positive? ||
                @brca1_seq_result.scan(/no mut/i).size.positive? ||
                @brca1_seq_result.scan(/no var|no fam|not det/i).size.positive?
            end

            def normal_brca2_seq?
              return if @brca2_seq_result.nil?

              @brca2_seq_result.downcase == '-ve' ||
                @brca2_seq_result.downcase == 'neg' ||
                @brca2_seq_result.downcase == 'nrg' ||
                @brca2_seq_result.scan(/neg|nrg|norm|-ve/i).size.positive? ||
                @brca2_seq_result.scan(/no mut/i).size.positive? ||
                @brca2_seq_result.scan(/no var|no fam|not det/i).size.positive?
            end

            def failed_brca1_mlpa_targeted_test?
              return if @brca1_mlpa_result.nil? || @brca1_mlpa_result == 'N/A'

              @brca1_mlpa_result.scan(/fail/i).size.positive? &&
                (@authoriseddate.nil? ||
                @record.raw_fields['servicereportidentifier'] == '06/03030')
            end

            def failed_brca2_mlpa_targeted_test?
              return if @brca2_mlpa_result.nil? || @brca2_mlpa_result == 'N/A'

              @brca2_mlpa_result.scan(/fail/i).size.positive? &&
                (@authoriseddate.nil? ||
                @record.raw_fields['servicereportidentifier'] == '06/03030')
            end

            def positive_seq_brca1?
              return if @brca1_seq_result.nil?

              @brca1_seq_result.scan(CDNA_REGEX).size.positive?
            end

            def positive_seq_brca2?
              return if @brca2_seq_result.nil?

              @brca2_seq_result.scan(CDNA_REGEX).size.positive?
            end

            def process_negative_gene(negative_gene, test_scope)
              negative_genotype = @genotype.dup
              negative_genotype.add_gene(negative_gene)
              negative_genotype.add_status(1)
              negative_genotype.add_test_scope(test_scope)
              @genotypes.append(negative_genotype)
            end

            def process_failed_gene(failed_gene, test_scope)
              failed_genotype = @genotype.dup
              failed_genotype.add_gene(failed_gene)
              failed_genotype.add_status(9)
              failed_genotype.add_test_scope(test_scope)
              @genotypes.append(failed_genotype)
            end

            def process_double_brca_negative(test_scope)
              %w[BRCA1 BRCA2].each do |negative_gene|
                genotype1 = @genotype.dup
                genotype1.add_gene(negative_gene)
                genotype1.add_status(1)
                genotype1.add_test_scope(test_scope)
                @genotypes.append(genotype1)
              end
              @genotypes
            end

            def process_double_brca_fail(test_scope)
              %w[BRCA1 BRCA2].each do |unknown_gene_test|
                genotype1 = @genotype.dup
                genotype1.add_gene(unknown_gene_test)
                genotype1.add_status(9)
                genotype1.add_test_scope(test_scope)
                @genotypes.append(genotype1)
              end
              @genotypes
            end

            def process_double_brca_unknown(test_scope)
              %w[BRCA1 BRCA2].each do |unknown_gene_test|
                genotype1 = @genotype.dup
                genotype1.add_gene(unknown_gene_test)
                genotype1.add_status(4)
                genotype1.add_test_scope(test_scope)
                @genotypes.append(genotype1)
              end
              @genotypes
            end

            def process_positive_cdnavariant(positive_gene, variant_field, test_scope)
              positive_genotype = @genotype.dup
              positive_genotype.add_gene(positive_gene)
              # positive_genotype.add_gene_location(cdna_variant)
              add_cdnavariant_from_variantfield(variant_field, positive_genotype)
              add_proteinimpact_from_variantfield(variant_field, positive_genotype)
              positive_genotype.add_status(2)
              positive_genotype.add_test_scope(test_scope)
              @genotypes.append(positive_genotype)
            end

            def add_cdnavariant_from_variantfield(variant_field, positive_genotype)
              Maybe(variant_field.match(CDNA_REGEX)[:cdna]).map do |x|
                positive_genotype.add_gene_location(x.tr(';', ''))
              end
            rescue StandardError
              @logger.debug 'Cannot add cdna variant'
            end

            def add_proteinimpact_from_variantfield(variant_field, positive_genotype)
              Maybe(variant_field.match(PROTEIN_REGEX)[:impact]).map do |x|
                positive_genotype.add_protein_impact(x)
              end
            rescue StandardError
              @logger.debug 'Cannot add protein impact'
            end

            def process_positive_exonvariant(positive_gene, exon_variant, test_scope)
              positive_genotype = @genotype.dup
              positive_genotype.add_gene(positive_gene)
              add_zygosity_from_exonicvariant(exon_variant, positive_genotype)
              add_varianttype_from_exonicvariant(exon_variant, positive_genotype)
              add_involved_exons_from_exonicvariant(exon_variant, positive_genotype)
              positive_genotype.add_status(2)
              positive_genotype.add_test_scope(test_scope)
              @genotypes.append(positive_genotype)
            end

            def add_zygosity_from_exonicvariant(exon_variant, positive_genotype)
              Maybe(exon_variant[:zygosity]).map { |x| positive_genotype.add_zygosity(x) }
            rescue StandardError
              @logger.debug 'Cannot add exon variant zygosity'
            end

            def add_varianttype_from_exonicvariant(exon_variant, positive_genotype)
              Maybe(exon_variant[:deldup]).map { |x| positive_genotype.add_variant_type(x) }
            rescue StandardError
              @logger.debug 'Cannot add exon variant type'
            end

            def add_involved_exons_from_exonicvariant(exon_variant, positive_genotype)
              Maybe(exon_variant[:exons]).map { |x| positive_genotype.add_exon_location(x) }
            rescue StandardError
              @logger.debug 'Cannot add exons involved in exonic variant'
            end
          end
        end
      end
    end
  end
end
