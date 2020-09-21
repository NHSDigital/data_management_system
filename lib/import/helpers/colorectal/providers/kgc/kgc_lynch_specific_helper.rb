require_relative 'kgc_constants'
require_relative 'kgc_helper'

module Import
  module Helpers
    module Colorectal
      module Providers
        module Kgc
          # Processing methods for Lynch specific genes
          module KgcLynchSpecificHelper
            include KgcConstants
            include KgcHelper

            def process_specific_lynchgenes(raw_genotype, clinicomm, genocolorectal, genotypes)
              if raw_genotype.scan(COLORECTAL_GENES_REGEX).size.positive?
                mutatedgene = raw_genotype.scan(COLORECTAL_GENES_REGEX).flatten
                if raw_genotype.scan(CDNA_REGEX).size.positive? && raw_genotype !~ EXON_REGEX
                  process_lynch_specific_cdna_change(raw_genotype, mutatedgene, clinicomm,
                                                     genocolorectal, genotypes)
                elsif EXON_REGEX.match(raw_genotype) && raw_genotype !~ CDNA_REGEX
                  process_lynch_specific_exon(raw_genotype, clinicomm, genocolorectal, genotypes)
                elsif EXON_REGEX.match(raw_genotype) && CDNA_REGEX.match(raw_genotype)
                  process_lynch_specific_exon_and_cdna_change(raw_genotype, clinicomm,
                                                              genocolorectal, genotypes)
                end
              elsif /no mutation|No mutation detected/i.match(raw_genotype)
                process_no_lynch_specific_gene_mutation(clinicomm, genocolorectal, genotypes)
              end
            end

            def add_result_to(genocolorectal, genotypes, result_details)
              attributes = %i[exon gene gene_location protein variant]
              exon, gene, gene_location, protein, variant = result_details.values_at(*attributes)

              genocolorectal.add_gene_colorectal(gene)        if gene
              genocolorectal.add_gene_location(gene_location) if gene_location
              genocolorectal.add_exon_location(exon)          if exon
              genocolorectal.add_variant_type(variant)        if variant
              genocolorectal.add_protein_impact(protein)      if protein
              genotypes.append(genocolorectal)
            end

            def process_lynch_specific_cdna_change(raw_genotype, mutatedgene, clinicomm,
                                                   genocolorectal, genotypes)
              mutatedcdna     = raw_genotype.scan(CDNA_REGEX).flatten
              mutatedprotein  = raw_genotype.scan(PROTEIN_REGEX_COLO).flatten
              mutations       = mutatedgene.zip(mutatedcdna, mutatedprotein)
              @logger.debug 'Found SPECIFIC LYNCH dna mutation in ' \
                            "#{raw_genotype.scan(COLORECTAL_GENES_REGEX)} LYNCH RELATED GENE(s) "\
                            "in position #{raw_genotype.scan(CDNA_REGEX)} " \
                            "with impact #{raw_genotype.scan(PROTEIN_REGEX_COLO)}"
              process_mutated_genes(mutations, genocolorectal, genotypes)
              negativegenes = specific_lynch_genes(clinicomm) - mutatedgene
              add_negative_test_for(negativegenes, genotypes, genocolorectal,
                                    NEGATIVE_LYNCH_SPECIFIC_TEST_LOG)
            end

            def process_lynch_specific_exon(raw_genotype, clinicomm, genocolorectal, genotypes)
              @logger.debug 'Found LYNCH_SPEC' \
              "#{EXON_REGEX.match(raw_genotype)[:deldupins]} "\
              "in #{COLORECTAL_GENES_REGEX.match(raw_genotype)[:colorectal]} " \
              'LYNCH RELATED GENE at ' \
              "position #{EXON_REGEX.match(raw_genotype)[:exno]}"
              mutatedgene     = raw_genotype.scan(COLORECTAL_GENES_REGEX).flatten
              negativegenes   = specific_lynch_genes(clinicomm) - mutatedgene
              add_negative_test_for(negativegenes, genotypes, genocolorectal, NEGATIVE_TEST_LOG)
              result = { gene: coloractal_gene_from(raw_genotype), exon: exon_from(raw_genotype),
                         variant: variant_from(raw_genotype) }
              add_result_to(genocolorectal, genotypes, result)
            end

            def process_lynch_specific_exon_and_cdna_change(raw_genotype, clinicomm, genocolorectal,
                                                            genotypes)
              @logger.debug lynch_specific_exon_and_cdna_change_log(raw_genotype)
              mutatedgene   = raw_genotype.scan(COLORECTAL_GENES_REGEX).flatten
              negativegenes = specific_lynch_genes(clinicomm) - mutatedgene
              add_negative_test_for(negativegenes, genotypes, genocolorectal, NEGATIVE_TEST_LOG)
              mutatedexongenotype = genocolorectal.dup_colo
              add_mutated_result_to(mutatedexongenotype, raw_genotype, genotypes)
              result = { gene: raw_genotype.scan(COLORECTAL_GENES_REGEX)[1].join,
                         gene_location: gene_location_from(raw_genotype),
                         protein: protein_impact_from(raw_genotype) }

              add_result_to(genocolorectal, genotypes, result)
            end

            def lynch_specific_exon_and_cdna_change_log(raw_genotype)
              "Found LYNCH_SPEC #{EXON_REGEX.match(raw_genotype)[:deldupins]} "\
              "in #{raw_genotype.scan(COLORECTAL_GENES_REGEX)[0]} LYNCH RELATED GENE at "\
              "position #{EXON_REGEX.match(raw_genotype)[:exno]} and " \
              "Mutation #{CDNA_REGEX.match(raw_genotype)[:dna]} in gene "\
              "#{raw_genotype.scan(COLORECTAL_GENES_REGEX)[0]} at " \
              "position #{raw_genotype.scan(CDNA_REGEX)}" \
              " with impact #{raw_genotype.scan(PROTEIN_REGEX_COLO)}"
            end

            def process_no_lynch_specific_gene_mutation(clinicomm, genocolorectal, genotypes)
              specific_lynch_genes = specific_lynch_genes(clinicomm)
              @logger.debug 'Found no mutation in lynch specific genes' \
              "Genes LYNCH SPECIFIC #{specific_lynch_genes} are normal"

              add_negative_test_for(specific_lynch_genes, genotypes, genocolorectal,
                                    NEGATIVE_TEST_LOG)
            end

            def specific_lynch_genes(clinicomm)
              clinicomm.scan(COLORECTAL_GENES_REGEX).flatten.map(&:upcase)
            end
          end
        end
      end
    end
  end
end
