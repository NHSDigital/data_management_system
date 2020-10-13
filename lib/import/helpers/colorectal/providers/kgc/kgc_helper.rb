require_relative 'kgc_constants'

module Import
  module Helpers
    module Colorectal
      module Providers
        module Kgc
          # Processing methods used in all results/genes
          module KgcHelper
            include KgcConstants

            def process_mutated_genes(mutations, genocolorectal,  genotypes)
              mutations.each do |gene, cdna, protein|
                mutatedgenotype = genocolorectal.dup_colo
                @logger.debug 'SUCCESSFUL gene parse for positive test for: '\
                              "#{gene}, #{cdna}, #{protein}"
                result_details = { gene: gene, gene_location: cdna, protein: protein }
                add_result_to(mutatedgenotype, genotypes, result_details)
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

            def add_mutated_result_to(mutatedexongenotype, raw_genotype, genotypes)
              mutated_result = { gene: raw_genotype.scan(COLORECTAL_GENES_REGEX)[0].join,
                                 exon: exon_from(raw_genotype),
                                 variant: variant_from(raw_genotype) }

              add_result_to(mutatedexongenotype, genotypes, mutated_result)
            end

            def add_negative_test_for(negativegenes, genotypes, genocolorectal, log_message)
              negativegenes.each do |negativegene|
                dup_genocolorectal = genocolorectal.dup_colo
                @logger.debug "#{log_message}: #{negativegene}"
                dup_genocolorectal.add_status(1)
                dup_genocolorectal.add_gene_colorectal(negativegene)
                dup_genocolorectal.add_protein_impact(nil)
                dup_genocolorectal.add_gene_location(nil)
                genotypes.append(dup_genocolorectal)
              end
            end

            def process_negative_genes(negativegenes, genotypes, genocolorectal, logging)
              return unless negativegenes.any?

              @logger.debug "#{logging}: #{negativegenes.flatten}"
              add_negative_test_for(negativegenes, genotypes, genocolorectal,
                                    logging)
            end

            def variant_from(raw_genotype)
              EXON_REGEX.match(raw_genotype)[:deldupins]
            end

            def exon_from(raw_genotype)
              EXON_REGEX.match(raw_genotype)[:exno]
            end

            def coloractal_gene_from(raw_genotype)
              COLORECTAL_GENES_REGEX.match(raw_genotype)[:colorectal]
            end

            def gene_location_from(raw_genotype)
              CDNA_REGEX.match(raw_genotype)[:dna]
            end

            def protein_impact_from(raw_genotype)
              PROTEIN_REGEX_COLO.match(raw_genotype)[:impact]
            end

            def non_lynch_genes_from(clinicomm)
              nonlynchgenes = []
              clinicomm.scan(NON_LYNCH_REGEX).each do |gene|
                nonlynchgenes.append(NON_LYNCH_MAP[gene])
              end

              nonlynchgenes
            end
          end
        end
      end
    end
  end
end
