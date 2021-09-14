require_relative 'kgc_constants'
require_relative 'kgc_helper'
module Import
  module Helpers
    module Brca
      module Providers
        module Kgc
          # Processing methods for Lynch genes
          module KgcBrcaHelper
            include KgcConstants
            include KgcHelper

            def process_brcagenes(raw_genotype, _clinicomm, genotype, genotypes)
              if raw_genotype.scan(BRCA_GENES_REGEX).size.positive?
                mutatedgene = raw_genotype.scan(BRCA_GENES_REGEX).flatten
                if raw_genotype.scan(CDNA_REGEX).size.positive? && raw_genotype !~ EXON_REGEX
                  process_cdna_change(raw_genotype, mutatedgene, genotype, genotypes)
                elsif EXON_REGEX.match(raw_genotype) && raw_genotype !~ CDNA_REGEX
                  process_exon(raw_genotype, genotype, genotypes)
                elsif EXON_REGEX.match(raw_genotype) && CDNA_REGEX.match(raw_genotype)
                  process_exon_and_cdna_change(raw_genotype, genotype, genotypes)
                end
              elsif /no mutation|No mutation detected/i.match(raw_genotype)
                process_no_mutation(genotypes, genotype)
              end
            end

            def process_cdna_change(raw_genotype, mutatedgene, genotype, genotypes)
              mutatedcdna    = raw_genotype.scan(CDNA_REGEX).flatten
              mutatedprotein = raw_genotype.scan(PROTEIN_REGEX).flatten
              mutations      = mutatedgene.zip(mutatedcdna, mutatedprotein)
              @logger.debug 'Found dna mutation in ' \
                            "#{raw_genotype.scan(BRCA_GENES_REGEX)} GENE(s) " \
                            "in position #{raw_genotype.scan(CDNA_REGEX)} " \
                            "with impact #{raw_genotype.scan(PROTEIN_REGEX)}"
              process_mutated_genes(mutations, genotype, genotypes)
              negativegenes = BRCAGENES - mutatedgene
              add_negative_test_for(negativegenes, genotypes, genotype, NEGATIVE_TEST_LOG)
            end

            def process_exon(raw_genotype, genotype, genotypes)
              @logger.debug "Found CHROMOSOME VARIANT #{variant_from(raw_genotype)} "\
                            "in #{brca_gene_from(raw_genotype)} GENE at "\
                            "position #{exon_from(raw_genotype)}"
              mutatedgene   = raw_genotype.scan(BRCA_GENES_REGEX).flatten
              negativegenes = BRCAGENES - mutatedgene
              add_negative_test_for(negativegenes, genotypes, genotype, NEGATIVE_TEST_LOG)
              result = { gene: brca_gene_from(raw_genotype), exon: exon_from(raw_genotype),
                         variant: variant_from(raw_genotype) }
              add_result_to(genotype, genotypes, result)
            end

            def process_exon_and_cdna_change(raw_genotype, genotype, genotypes)
              mutatedgene   = raw_genotype.scan(BRCA_GENES_REGEX).flatten
              negativegenes = BRCAGENES - mutatedgene
              add_negative_test_for(negativegenes, genotypes, genotype, NEGATIVE_TEST_LOG)
              mutatedexongenotype = genotype.dup
              add_mutated_result_to(mutatedexongenotype, raw_genotype, genotypes)
              result = { gene: raw_genotype.scan(BRCA_GENES_REGEX)[1].join,
                         gene_location: gene_location_from(raw_genotype),
                         protein: protein_impact_from(raw_genotype) }

              add_result_to(genotype, genotypes, result)
            end

            def process_no_mutation(genotypes, genotype)
              @logger.debug 'Found no mutation'
              add_negative_test_for(BRCAGENES, genotypes, genotype, NEGATIVE_TEST_LOG)
            end
          end
        end
      end
    end
  end
end
