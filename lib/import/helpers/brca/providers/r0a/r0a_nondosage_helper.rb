module Import
  module Helpers
    module Brca
      module Providers
        module R0a
          # Helper methods for R0A germline extractor
          module R0aNondosageHelper
            include Import::Helpers::Brca::Providers::R0a::R0aConstants

            def non_dosage_test?
              @non_dosage_record_map[:moleculartestingtype].uniq.join.scan(/dosage/i).size.zero?
            end

            def split_multiplegenes_nondosage_map
              @non_dosage_record_map[:exon].each.with_index do |exon, index|
                next unless exon.scan(BRCA_GENES_REGEX).size.positive?

                if exon.scan(BRCA_GENES_REGEX).uniq.size > 1
                  @non_dosage_record_map[:exon][index] =
                    @non_dosage_record_map[:exon][index].scan(BRCA_GENES_REGEX).uniq
                  @non_dosage_record_map[:exon][index].flatten
                  @non_dosage_record_map[:genotype][index] =
                    edit_nondosage_genotype_field(exon, index)
                  @non_dosage_record_map[:genotype2][index] =
                    edit_nondosage_genotype2_field(exon, index)
                end
              end
              @non_dosage_record_map[:exon] = @non_dosage_record_map[:exon].flatten
              @non_dosage_record_map[:genotype] = @non_dosage_record_map[:genotype].flatten
              @non_dosage_record_map[:genotype2] = @non_dosage_record_map[:genotype2].flatten
            end

            def edit_nondosage_genotype_field(exon, index)
              if @non_dosage_record_map[:genotype][index] == 'BRCA1 Normal, BRCA2 Normal'
                @non_dosage_record_map[:genotype][index] = ['NGS Normal'] * 2
                @non_dosage_record_map[:genotype][index] =
                  @non_dosage_record_map[:genotype][index].flatten
              elsif @non_dosage_record_map[:genotype][index].scan(/Normal, /i).size.positive? ||
                    @non_dosage_record_map[:genotype][index].scan(/,.+Normal/i).size.positive?
                @non_dosage_record_map[:genotype][index] =
                  @non_dosage_record_map[:genotype][index] = ['NGS Normal'] * 2
              elsif @non_dosage_record_map[:genotype][index] == 'Normal'
                @non_dosage_record_map[:genotype][index] =
                  ['Normal'] * exon.scan(BRCA_GENES_REGEX).uniq.size
                @non_dosage_record_map[:genotype][index] =
                  @non_dosage_record_map[:genotype][index].flatten
              else
                @non_dosage_record_map[:genotype][index] =
                  @non_dosage_record_map[:genotype][index]
              end
              @non_dosage_record_map[:genotype] = @non_dosage_record_map[:genotype].flatten
            end

            def edit_nondosage_genotype2_field(exon, index)
              if !@non_dosage_record_map[:genotype2][index].nil? &&
                 @non_dosage_record_map[:genotype2][index].scan(/coverage at 100X/).size.positive?
                @non_dosage_record_map[:genotype2][index] = ['NGS Normal'] * 2
                @non_dosage_record_map[:genotype2][index] =
                  @non_dosage_record_map[:genotype2][index].flatten
              elsif !@non_dosage_record_map[:genotype2][index].nil? &&
                    @non_dosage_record_map[:genotype2][index].empty?
                @non_dosage_record_map[:genotype2][index] = ['MLPA Normal'] * 2
                @non_dosage_record_map[:genotype2][index] =
                  @non_dosage_record_map[:genotype2][index].flatten
              elsif @non_dosage_record_map[:genotype2][index].nil? &&
                    @non_dosage_record_map[:genotype][index].is_a?(String) &&
                    @non_dosage_record_map[:genotype][index].scan(/MSH2/).size.positive?
                @non_dosage_record_map[:genotype2][index] =
                  [''] * exon.scan(BRCA_GENES_REGEX).size
                @non_dosage_record_map[:genotype2][index] =
                  @non_dosage_record_map[:genotype2][index].flatten
              elsif @non_dosage_record_map[:genotype2][index] == 'Normal' ||
                    @non_dosage_record_map[:genotype2][index].nil? ||
                    @non_dosage_record_map[:genotype2][index] == 'Fail'
                @non_dosage_record_map[:genotype2][index] =
                  ['Normal'] * exon.scan(BRCA_GENES_REGEX).uniq.size
                @non_dosage_record_map[:genotype2][index] =
                  @non_dosage_record_map[:genotype2][index].flatten
              end
            end

            def process_grouped_non_dosage_tests(grouped_tests, genotype, genotypes)
              if (@non_dosage_record_map[:moleculartestingtype].uniq & DO_NOT_IMPORT).empty?
                grouped_tests.each do |gene, genetic_info|
                  # next unless MOLTEST_MAP[selected_genes].include? gene
                  if gene == 'No Gene'
                    @logger.debug("Nothing to do for #{gene} and #{genetic_info}")
                  elsif cdna_match?(genetic_info)
                    process_non_dosage_cdna(gene, genetic_info, genotype, genotypes)
                  elsif genetic_info.join(',').match(EXON_LOCATION_REGEX) &&
                        exon_match?(genetic_info)
                    process_brca_gene_and_exon_match(genotype, gene, genetic_info, genotypes)
                  elsif !cdna_match?(genetic_info) && !exon_match?(genetic_info) &&
                        normal?(genetic_info)
                    process_non_cdna_normal(gene, genetic_info, genotype, genotypes)
                  elsif !cdna_match?(genetic_info) && !exon_match?(genetic_info) &&
                        !normal?(genetic_info) && fail?(genetic_info)
                    process_non_cdna_fail(gene, genetic_info, genotype, genotypes)
                  end
                end
              else
                @logger.debug('Nothing to do')
              end
            end

            def process_non_dosage_cdna(gene, genetic_info, genotype, genotypes)
              genotype_dup = genotype.dup
              process_non_brca_genes(genotype_dup, gene, genetic_info, genotypes,
                                     genotype)
            end

            def tests_from_non_dosage_record(genes)
              return if genes.nil?

              genes.zip(@non_dosage_record_map[:genotype],
                        @non_dosage_record_map[:genotype2]).uniq
            end

            def process_non_dosage_test_exons(genes)
              @non_dosage_record_map[:exon].each do |exons|
                if exons =~ BRCA_GENES_REGEX
                  genes.append(BRCA_GENES_REGEX.match(exons.upcase)[:brca])
                else
                  genes.append('No Gene')
                end
              end
            end
          end
        end
      end
    end
  end
end
