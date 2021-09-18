module Import
  module Helpers
    module Brca
      module Providers
        module R0a
          # Helper methods for R0A germline extractor
          module R0aDosageHelper
            include Import::Helpers::Brca::Providers::R0a::R0aConstants

            def split_multiplegenes_dosage_map
              @dosage_record_map[:exon].each.with_index do |exon, index|
                if exon.scan(BRCA_GENES_REGEX).size > 1
                  @dosage_record_map[:exon][index] =
                    @dosage_record_map[:exon][index].scan(BRCA_GENES_REGEX).flatten.each do |gene|
                      gene.concat('_MLPA')
                    end
                  @dosage_record_map[:genotype][index] =
                    edit_dosage_genotype_field(exon, index)
                  @dosage_record_map[:genotype2][index] =
                    edit_dosage_genotype2_field(exon, index)
                end
              end
              @dosage_record_map[:exon] = @dosage_record_map[:exon].flatten
              @dosage_record_map[:genotype] = @dosage_record_map[:genotype].flatten
              @dosage_record_map[:genotype2] = @dosage_record_map[:genotype2].flatten
            end

            def edit_dosage_genotype_field(exon, index)
              case @dosage_record_map[:genotype][index]
              when 'Normal'
                @dosage_record_map[:genotype][index] =
                  ['Normal'] * exon.scan(BRCA_GENES_REGEX).size
                @dosage_record_map[:genotype][index] =
                  @dosage_record_map[:genotype][index].flatten
              when 'BRCA1 Normal, BRCA2 Normal'
                @dosage_record_map[:genotype][index] = ['NGS Normal'] * 2
                @dosage_record_map[:genotype][index] =
                  @dosage_record_map[:genotype][index].flatten
              end
            end

            def edit_dosage_genotype2_field(_exon, index)
              if !@dosage_record_map[:genotype2][index].nil? &&
                 @dosage_record_map[:genotype2][index].empty?
                @dosage_record_map[:genotype2][index] = ['MLPA Normal'] * 2
                @dosage_record_map[:genotype2][index] =
                  @dosage_record_map[:genotype2][index].flatten
              elsif !@dosage_record_map[:genotype2][index].nil? &&
                    @dosage_record_map[:genotype2][index].scan(
                      /100% coverage at 100X/
                    ).size.positive?
                @dosage_record_map[:genotype2][index] = ['NGS Normal'] * 2
                @dosage_record_map[:genotype2][index] =
                  @dosage_record_map[:genotype2][index].flatten
              end
            end

            def dosage_test?
              @dosage_record_map[:moleculartestingtype].uniq.join.scan(/dosage/i).size.positive?
            end

            def process_dosage_test_exons(genes)
              @dosage_record_map[:exon].map do |exons|
                if exons.scan(BRCA_GENES_REGEX).count.positive?
                  exons.scan(BRCA_GENES_REGEX).flatten.each { |gene| genes.append(gene) }
                else
                  genes.append('No Gene')
                end
              end
            end

            def tests_from_dosage_record(genes)
              return if genes.nil?

              genes.zip(@dosage_record_map[:genotype],
                        @dosage_record_map[:genotype2]).uniq
            end

            def process_grouped_dosage_tests(grouped_tests, genotype, genotypes)
              if (@non_dosage_record_map[:moleculartestingtype].uniq & DO_NOT_IMPORT).empty?
                grouped_tests.compact.select do |gene, genetic_info|
                  process_dosage_gene(gene, genetic_info, genotype, genotypes)
                end
              else
                @logger.debug('Nothing to do')
              end
            end

            def process_dosage_gene(gene, genetic_info, genotype, genotypes)
              if !brca_gene_match?(genetic_info)
                non_brca_gene_record(gene, genetic_info, genotype, genotypes)
              elsif brca_gene_match?(genetic_info) && !exon_match?(genetic_info)
                brca_gene_record_noexon(genetic_info, gene, genotype, genotypes)
              elsif brca_gene_match?(genetic_info) && exon_match?(genetic_info)
                brca_gene_record_withexon(genetic_info, gene, genotype, genotypes)
              end
            end

            def non_brca_gene_record(gene, genetic_info, genotype, genotypes)
              if gene == 'No Gene'
                @logger.debug("Nothing to do for #{gene} and #{genetic_info}")
              elsif (!cdna_match?(genetic_info) && !exon_match?(genetic_info) &&
                    normal?(genetic_info)) || genetic_info.join(',').match(/evidence/i)
                process_non_cdna_normal(gene, genetic_info, genotype, genotypes)
              elsif cdna_match?(genetic_info)
                process_non_dosage_cdna(gene, genetic_info, genotype, genotypes)
                @logger.debug("IDENTIFIED #{gene}," \
                              "#{cdna_from(genetic_info)} from #{genetic_info}")
              elsif genetic_info.join(',').match(EXON_LOCATION_REGEX) && exon_match?(genetic_info)
                process_brca_gene_and_exon_match(genotype, gene, genetic_info, genotypes)
              elsif !genetic_info.join(',').match(EXON_LOCATION_REGEX) && exon_match?(genetic_info)
                negative_test_exon_variant(gene, genetic_info, genotype, genotypes)
              elsif genetic_info.join(',').empty?
                @logger.debug("IDENTIFIED FALSE POSITIVE #{gene} #{genetic_info}, skipping entry")
              end
            end

            def negative_test_exon_variant(gene, genetic_info, genotype, genotypes)
              case genetic_info.join(',')
              when /normal/i, /evidence/i
                process_non_cdna_normal(gene, genetic_info, genotype, genotypes)
              when /control/i
                @logger.debug("IDENTIFIED FALSE POSITIVE #{gene}"\
                              " #{genetic_info}, skipping entry")
              end
              genotypes
            end

            def brca_gene_record_noexon(genetic_info, gene, genotype, genotypes)
              if genetic_info.join(',').match(BRCA_GENES_REGEX)[:brca] == gene
                genotype_dup = genotype.dup
                add_gene_and_status_to(genotype_dup, gene, 1, genotypes)
              else
                @logger.debug("IDENTIFIED FALSE POSITIVE #{gene} #{genetic_info}, skipping entry")
              end
            end

            def brca_gene_record_withexon(genetic_info, gene, genotype, genotypes)
              if genetic_info.join(',').match(BRCA_GENES_REGEX)[:brca] == gene
                process_brca_gene_and_exon_match(genotype, gene, genetic_info, genotypes)
              else
                @logger.debug("IDENTIFIED FALSE POSITIVE #{gene} #{genetic_info}, skipping entry")
              end
            end
          end
        end
      end
    end
  end
end
