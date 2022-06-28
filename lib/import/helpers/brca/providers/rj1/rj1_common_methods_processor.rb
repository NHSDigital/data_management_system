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
              return false if @brca1_mlpa_result.nil? && @brca2_mlpa_result.nil?

              @brca1_mutation.nil? && @brca2_mutation.nil? &&
                @brca1_seq_result.nil? && @brca2_seq_result.nil? &&
                @brca1_mlpa_result&.downcase == 'n/a' && @brca2_mlpa_result&.downcase == 'n/a'
            end
            # rubocop:enable Metrics/CyclomaticComplexity

            def brca_mutation?(brca_mutation_field)
              return false if brca_mutation_field.nil?

              brca_mutation_field.scan(CDNA_REGEX).size.positive?
            end

            def normal_brca12_seq_result?(brca12_seq_result)
              return false if brca12_seq_result.nil?

              brca12_seq_result.downcase == '-ve' ||
                brca12_seq_result.downcase == 'neg' ||
                brca12_seq_result.downcase == 'nrg' ||
                brca12_seq_result.scan(/neg|nrg|norm|-ve/i).size.positive? ||
                brca12_seq_result.scan(/no mut/i).size.positive? ||
                brca12_seq_result.scan(/no var|no fam|not det/i).size.positive?
            end

            def failed_brca12_mlpa_targeted_test?(brca12_mlpa_result)
              return false if brca12_mlpa_result.nil? || brca12_mlpa_result == 'N/A'

              brca12_mlpa_result.scan(/fail/i).size.positive? &&
                (@authoriseddate.nil? ||
                @record.raw_fields['servicereportidentifier'] == '06/03030')
            end

            def positive_brca12_seq?(brca12_seq_result)
              return false if brca12_seq_result.nil?

              brca12_seq_result.scan(CDNA_REGEX).size.positive?
            end

            def process_negative_or_failed_gene(negfail_gene, negfailstatus, test_scope)
              negative_or_failed_genotype = @genotype.dup
              negative_or_failed_genotype.add_gene(negfail_gene)
              negative_or_failed_genotype.add_status(negfailstatus)
              negative_or_failed_genotype.add_test_scope(test_scope)
              @genotypes.append(negative_or_failed_genotype)
            end

            def process_double_brca_status(test_status, test_scope)
              %w[BRCA1 BRCA2].each do |double_brca|
                genotype1 = @genotype.dup
                genotype1.add_gene(double_brca)
                genotype1.add_status(test_status)
                genotype1.add_test_scope(test_scope)
                @genotypes.append(genotype1)
              end
              @genotypes
            end

            def process_positive_cdnavariant(positive_gene, variant_field, test_scope)
              positive_genotype = @genotype.dup
              positive_genotype.add_gene(positive_gene)
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
