module Import
  module Brca
    module Providers
      module Manchester
        # Split multigene dosage records
        class DosageMultigeneSplitter
          include Import::Helpers::Brca::Providers::R0a::R0aConstants

          attr_accessor :dosage_record

          def initialize(dosage_record)
            @dosage_record = dosage_record
          end

          def split_dosage_multiplegenes
            dosage_record[:exon].each.with_index do |exon, index|
              if exon.scan(BRCA_GENES_REGEX).size > 1
                dosage_record[:exon][index] =
                  dosage_record[:exon][index].scan(BRCA_GENES_REGEX).flatten.each do |gene|
                    gene.concat('_MLPA')
                  end
                dosage_record[:genotype][index] =
                  edit_dosage_genotype_field(exon, index)
                dosage_record[:genotype2][index] =
                  edit_dosage_genotype2_field(exon, index)
              end
            end
            dosage_record[:exon] = dosage_record[:exon].flatten
            dosage_record[:genotype] = dosage_record[:genotype].flatten
            dosage_record[:genotype2] = dosage_record[:genotype2].flatten
            dosage_record
          end

          private

          def edit_dosage_genotype_field(exon, index)
            case dosage_record[:genotype][index]
            when 'Normal'
              dosage_record[:genotype][index] =
                ['Normal'] * exon.scan(BRCA_GENES_REGEX).size
              dosage_record[:genotype][index] =
                dosage_record[:genotype][index].flatten
            when 'BRCA1 Normal, BRCA2 Normal'
              dosage_record[:genotype][index] = ['NGS Normal'] * 2
              dosage_record[:genotype][index] =
                dosage_record[:genotype][index].flatten
            end
          end

          def edit_dosage_genotype2_field(_exon, index)
            if !dosage_record[:genotype2][index].nil? &&
               dosage_record[:genotype2][index].empty?
              dosage_record[:genotype2][index] = ['MLPA Normal'] * 2
              dosage_record[:genotype2][index] =
                dosage_record[:genotype2][index].flatten
            elsif !dosage_record[:genotype2][index].nil? &&
                  dosage_record[:genotype2][index].scan(
                    /100% coverage at 100X/
                  ).size.positive?
              dosage_record[:genotype2][index] = ['NGS Normal'] * 2
              dosage_record[:genotype2][index] =
                dosage_record[:genotype2][index].flatten
            end
          end
        end
      end
    end
  end
end
