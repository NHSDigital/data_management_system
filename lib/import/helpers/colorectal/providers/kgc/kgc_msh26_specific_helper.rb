require_relative 'kgc_constants'
require_relative 'kgc_helper'

module Import
  module Helpers
    module Colorectal
      module Providers
        module Kgc
          # Processing methods for MSH2 and MSH6 specific genes
          module KgcMsh26SpecificHelper
            include KgcConstants
            include KgcHelper

            def process_msh2_6_specific_genes(raw_genotype, _clinicomm, genocolorectal, genotypes)
              if raw_genotype.scan(COLORECTAL_GENES_REGEX).size.positive?
                mutatedgene = raw_genotype.scan(COLORECTAL_GENES_REGEX).flatten
                if raw_genotype.scan(CDNA_REGEX).size.positive? && raw_genotype !~ EXON_REGEX
                  process_msh26_specific_cdna_change(raw_genotype, mutatedgene, genocolorectal,
                                                     genotypes)
                elsif EXON_REGEX.match(raw_genotype) && raw_genotype !~ CDNA_REGEX
                  process_msh26_specific_specific_exon(raw_genotype, genocolorectal, genotypes)
                elsif EXON_REGEX.match(raw_genotype) && CDNA_REGEX.match(raw_genotype)
                  rocess_msh26_specific_specific_exon_and_cdna_change(raw_genotype, genocolorectal,
                                                                      genotypes)
                end
              elsif /no mutation|No mutation detected/i.match(raw_genotype)
                process_no_msh2_or_6_specific_gene_mutation(genocolorectal, genotypes)
              end
            end

            def process_msh26_specific_cdna_change(raw_genotype, mutatedgene, genocolorectal,
                                                   genotypes)
              mutatedcdna    = raw_genotype.scan(CDNA_REGEX).flatten
              mutatedprotein = raw_genotype.scan(PROTEIN_REGEX_COLO).flatten
              mutations      = mutatedgene.zip(mutatedcdna, mutatedprotein)
              @logger.debug 'Found SPECIFIC LYNCH dna mutation in ' \
              "#{raw_genotype.scan(COLORECTAL_GENES_REGEX)} LYNCH SPECIFIC GENE(s) in "\
              "position #{raw_genotype.scan(CDNA_REGEX)}" \
              " with impact #{raw_genotype.scan(PROTEIN_REGEX_COLO)}"
              process_mutated_genes(mutations, genocolorectal, genotypes)
              negativegenes = MSH2_MSH6_GENES - mutatedgene
              add_negative_test_for(negativegenes, genotypes, genocolorectal)
            end

            def process_msh26_specific_specific_exon(raw_genotype, genocolorectal, genotypes)
              @logger.debug 'Found LYNCH CHROMOSOME ' \
              "#{EXON_REGEX.match(raw_genotype)[:deldupins]} " \
              "in #{COLORECTAL_GENES_REGEX.match(raw_genotype)[:colorectal]} " \
              'LYNCH SPECIFIC GENE at '\
              "position #{EXON_REGEX.match(raw_genotype)[:exno]}"
              mutatedgene   = raw_genotype.scan(COLORECTAL_GENES_REGEX).flatten
              negativegenes = MSH2_MSH6_GENES - mutatedgene
              add_negative_test_for(negativegenes, genotypes, genocolorectal)
              result = { gene: coloractal_gene_from(raw_genotype), exon: exon_from(raw_genotype),
                         variant: variant_from(raw_genotype) }
              add_result_to(genocolorectal, genotypes, result)
            end

            def process_msh26_specific_specific_exon_and_cdna_change(raw_genotype, genocolorectal,
                                                                     genotypes)
              mutatedgene   = raw_genotype.scan(COLORECTAL_GENES_REGEX).flatten
              negativegenes = %w[MSH2 MSH6] - mutatedgene
              add_negative_test_for(negativegenes, genotypes, genocolorectal)
              mutatedexongenotype = genocolorectal.dup_colo
              add_mutated_result_to(mutatedexongenotype, raw_genotype, genotypes)

              result = { gene: raw_genotype.scan(COLORECTAL_GENES_REGEX)[1].join,
                         gene_location: gene_location_from(raw_genotype),
                         protein: protein_impact_from(raw_genotype) }
              add_result_to(genocolorectal, genotypes, result)
            end

            def process_no_msh2_or_6_specific_gene_mutation(genocolorectal, genotypes)
              @logger.debug 'Found no mutation in MSH2/MSH6 lynch genes'

              add_negative_test_for(MSH2_MSH6_GENES, genotypes, genocolorectal, NEGATIVE_TEST_LOG)
            end
          end
        end
      end
    end
  end
end
