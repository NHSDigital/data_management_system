module Import
  module Brca
    module Providers
      module Manchester
        # Split multigene non dosage records
        class NonDosageMultigeneSplitter
          include Import::Helpers::Brca::Providers::R0a::R0aConstants

          attr_accessor :non_dosage_record

          def initialize(non_dosage_record)
            @non_dosage_record = non_dosage_record
          end

          def split_non_dosage_multiple_genes
            non_dosage_record[:exon].each_with_index do |exon, index|
              next unless exon.scan(BRCA_GENES_REGEX).size.positive?

              if exon.scan(BRCA_GENES_REGEX).uniq.size > 1
                non_dosage_record[:exon][index] =
                  non_dosage_record[:exon][index].scan(BRCA_GENES_REGEX).uniq
                non_dosage_record[:exon][index].flatten
                non_dosage_record[:genotype][index] =
                  edit_nondosage_genotype_field(exon, index)
                non_dosage_record[:genotype2][index] =
                  edit_nondosage_genotype2_field(exon, index)
              end
            end
            non_dosage_record[:exon] = non_dosage_record[:exon].flatten
            non_dosage_record[:genotype] = non_dosage_record[:genotype].flatten
            non_dosage_record[:genotype2] = non_dosage_record[:genotype2].flatten
            non_dosage_record
          end

          private

          def edit_nondosage_genotype_field(exon, index)
            if non_dosage_record[:genotype][index] == 'BRCA1 Normal, BRCA2 Normal'
              non_dosage_record[:genotype][index] = ['NGS Normal'] * 2
            elsif non_dosage_record[:genotype][index].scan(/Normal, /i).size.positive? ||
                  non_dosage_record[:genotype][index].scan(/,.+Normal/i).size.positive?
              non_dosage_record[:genotype][index] =
                non_dosage_record[:genotype][index] = ['NGS Normal'] * 2
            elsif non_dosage_record[:genotype][index] == 'Normal'
              non_dosage_record[:genotype][index] =
                ['Normal'] * exon.scan(BRCA_GENES_REGEX).uniq.size
            else
              non_dosage_record[:genotype][index] =
                non_dosage_record[:genotype][index]
            end
          end

          def edit_nondosage_genotype2_field(exon, index)
            if !non_dosage_record[:genotype2][index].nil? &&
               non_dosage_record[:genotype2][index].scan(/coverage at 100X/).size.positive?
              non_dosage_record[:genotype2][index] = ['NGS Normal'] * 2
            elsif !non_dosage_record[:genotype2][index].nil? &&
                  non_dosage_record[:genotype2][index].empty?
              non_dosage_record[:genotype2][index] = ['MLPA Normal'] * 2
            elsif non_dosage_record[:genotype2][index].nil? &&
                  non_dosage_record[:genotype][index].is_a?(String) &&
                  non_dosage_record[:genotype][index].scan(/MSH2/).size.positive?
              non_dosage_record[:genotype2][index] =
                [''] * exon.scan(BRCA_GENES_REGEX).size
            elsif non_dosage_record[:genotype2][index] == 'Normal' ||
                  non_dosage_record[:genotype2][index].nil? ||
                  non_dosage_record[:genotype2][index] == 'Fail'
              non_dosage_record[:genotype2][index] =
                ['Normal'] * exon.scan(BRCA_GENES_REGEX).uniq.size
            end
          end
        end
      end
    end
  end
end
