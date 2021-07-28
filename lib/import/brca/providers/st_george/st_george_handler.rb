require 'possibly'
require 'pry'

module Import
  module Brca
    module Providers
      module StGeorge
        # Process St George-specific record details into generalized internal genotype format
        class StGeorgeHandler < Import::Brca::Core::ProviderHandler
          PASS_THROUGH_FIELDS = %w[age sex consultantcode collecteddate
                                   receiveddate authoriseddate servicereportidentifier
                                   providercode receiveddate sampletype] .freeze
          CDNA_REGEX = /c\.(?<cdna>[0-9]+[^\s]+)|c\.\[(?<cdna>(.*?))\]/i.freeze
          
          DEPRECATED_BRCA_NAMES_MAP = { 'BR1'    => 'BRCA1',
                                        'B1'     => 'BRCA1',
                                        'BRCA 1' => 'BRCA1',
                                        'BR2'    => 'BRCA2',
                                        'B2'     => 'BRCA2',
                                        'BRCA 2' => 'BRCA2'
                                      }.freeze

          BRCA_GENES_REGEX = /(?<brca>BRCA1|
                                     BRCA2|
                                     ATM|
                                     CHEK2|
                                     PALB2|
                                     MLH1|
                                     MSH2|
                                     MSH6|
                                     MUTYH|
                                     SMAD4|
                                     NF1|
                                     NF2|
                                     SMARCB1|
                                     LZTR1)/xi.freeze
                                     

          DEPRECATED_BRCA_NAMES_REGEX = /B1|BR1|BRCA\s1|B2|BR2|BRCA\s2/i

          EXON_VARIANT_REGEX = /exon\s(?<exons>[0-9]+(-[0-9]+)?)\s(?<variant>del|dup|ins)/i.freeze

          def initialize(batch)
            @extractor = Import::ExtractionUtilities::LocationExtractor.new
            @failed_genotype_parse_counter = 0
            super
          end

          def process_fields(record)
            genotype = Import::Brca::Core::GenotypeBrca.new(record)
            genotype.add_passthrough_fields(record.mapped_fields,
                                            record.raw_fields,
                                            PASS_THROUGH_FIELDS)
            add_organisationcode_testresult(genotype)
            process_genetictestcope(genotype, record)
            # process_gene(genotype, record)
            # process_cdna_change(genotype, record)
            # process_variants_from_report(genotype, record)
            # @persister.integrate_and_store(genotype)
            res = process_variants_from_record(genotype, record)
            res.each { |cur_genotype| @persister.integrate_and_store(cur_genotype) }
            
          end

          def add_organisationcode_testresult(genotype)
            genotype.attribute_map['organisationcode_testresult'] = '697N0'
          end

          def process_variants_from_record(genotype, record)
            genotypes = []
            positive_gene = []
            gene = record.raw_fields['genotype'].scan(BRCA_GENES_REGEX)
            deprecated_gene = record.raw_fields['genotype'].scan(DEPRECATED_BRCA_NAMES_REGEX)
            if gene.present?
              positive_gene.append(gene.join)
            elsif deprecated_gene.present?
              positive_gene.append(DEPRECATED_BRCA_NAMES_MAP[deprecated_gene.join])
            else @logger.debug "Unable to extract gene"
            end 
            if ashkenazi?(record) || polish?(record) || full_screen?(record)
              if positive_cdna?(record) || positive_exonvariant?(record)
                negative_gene = ["BRCA1","BRCA2"] - positive_gene
                genotype.add_gene(positive_gene.join)
                process_positive_variants(genotype, record)
                genotypes.append(genotype)
                genotype_dup = genotype.dup
                genotype_dup.add_gene(negative_gene.join)
                genotype_dup.add_status(1)
                genotypes.append(genotype_dup)
              elsif normal?(record)
                ["BRCA1","BRCA2"].each do |negative_gene|
                  genotype_dup = genotype.dup
                  genotype_dup.add_gene(negative_gene)
                  genotype_dup.add_status(1)
                  genotypes.append(genotype_dup)
                end
              end
            elsif targeted_test?(record) || void_genetictestscope?(record)
              if positive_cdna?(record) || positive_exonvariant?(record)
                process_gene(genotype, record)
                process_positive_variants(genotype, record)
                genotypes.append(genotype)
              elsif normal?(record)
                genotype_dup = genotype.dup
                genotype_dup.add_gene(negative_gene)
                genotype_dup.add_status(1)
                genotypes.append(genotype_dup)
              end
            end
            genotypes
          end

          def process_fullscreen_records(genotype, record)
          end

          def process_genetictestcope(genotype, record)
            if ashkenazi?(record)
              genotype.add_test_scope(:aj_screen)
            elsif polish?(record)
              genotype.add_test_scope(:polish_screen)
            elsif targeted_test?(record)
              genotype.add_test_scope(:targeted_mutation)
            elsif full_screen?(record)
              genotype.add_test_scope(:full_screen)
            elsif void_genetictestscope?(record)
              @logger.debug "Unknown moleculartestingtype"
            end
          end

          def process_gene(genotype, record)
            if record.raw_fields['genotype'].scan(BRCA_GENES_REGEX).size.positive? 
              genotype.add_gene($LAST_MATCH_INFO[:brca])
              @logger.debug "SUCCESSFUL gene parse for: #{$LAST_MATCH_INFO[:brca]}"
            elsif deprecated_brca_genenames?(record)
              add_gene_from_deprecated_nomenclature(genotype, record)
            elsif record.raw_fields['moleculartestingtype'].scan(BRCA_GENES_REGEX).size.positive?
              genotype.add_gene($LAST_MATCH_INFO[:brca])
              @logger.debug "SUCCESSFUL gene parse for: #{$LAST_MATCH_INFO[:brca]}"
            elsif deprecated_brca_genenames_moleculartestingtype?(record)
              add_gene_from_deprecated_nomenclature_moleculartestingtype(genotype, record)
              @logger.debug "FAILED gene parse for: #{record.raw_fields['genotype']}"
            end
          end

          def process_positive_variants(genotype, record)
            if positive_cdna?(record)
              process_cdna_variant(genotype, record)
            elsif positive_exonvariant?(record)
              process_exonic_variant(genotype, record)
            # elsif normal?(genotype, record)
            #   process_normal_record(genotype, record)
            #   @logger.debug "NORMAL record parse for: #{record.raw_fields['genotype']}"
            else
              @logger.debug "FAILED variant parse for: #{record.raw_fields['genotype']}"
            end
          end

          def add_gene_from_deprecated_nomenclature(genotype, record)
            genename = record.raw_fields['genotype'].scan(DEPRECATED_BRCA_NAMES_REGEX).flatten.join
            genotype.add_gene(DEPRECATED_BRCA_NAMES_MAP[genename])
          end

          def deprecated_brca_genenames?(record)
            genename = record.raw_fields['genotype'].scan(DEPRECATED_BRCA_NAMES_REGEX).flatten.join
            DEPRECATED_BRCA_NAMES_MAP[genename].present?
          end

          def deprecated_brca_genenames_moleculartestingtype?(record)
            genename = record.raw_fields['moleculartestingtype'].
                        scan(DEPRECATED_BRCA_NAMES_REGEX).flatten.join
            DEPRECATED_BRCA_NAMES_MAP[genename].present?
          end

          def add_gene_from_deprecated_nomenclature_moleculartestingtype(genotype, record)
            genename = record.raw_fields['moleculartestingtype'].
                       scan(DEPRECATED_BRCA_NAMES_REGEX).flatten.join
            genotype.add_gene(DEPRECATED_BRCA_NAMES_MAP[genename])
          end

          def process_exonic_variant(genotype, record)
            if record.raw_fields['genotype'].scan(EXON_VARIANT_REGEX).size.positive?
              genotype.add_exon_location($LAST_MATCH_INFO[:exons])
              genotype.add_variant_type($LAST_MATCH_INFO[:variant])
              genotype.add_status(2)
              @logger.debug "SUCCESSFUL cdna change parse for: #{record.raw_fields['genotype']}"
            end
          end

          def process_cdna_variant(genotype, record)
            if record.raw_fields['genotype'].scan(CDNA_REGEX).size.positive?
              genotype.add_gene_location($LAST_MATCH_INFO[:cdna])
              genotype.add_status(2)
              @logger.debug "SUCCESSFUL cdna change parse for: #{$LAST_MATCH_INFO[:cdna]}"
            end
          end

          def process_normal_record(genotype, record)
              genotype.add_status(1)
              @logger.debug "SUCCESSFUL cdna change parse for: #{record.raw_fields['genotype']}"
          end

          def normal?(record)
            variant = record.raw_fields['genotype']
            moltesttype = record.raw_fields['moleculartestingtype']
            variant.scan(/NO PATHOGENIC|Normal|N\/N|NOT DETECTED/i).size.positive? ||
            moltesttype.scan(/unaffected/i).size.positive?
          end

          def positive_cdna?(record)
            variant = record.raw_fields['genotype']
            variant.scan(CDNA_REGEX).size.positive?
          end

          def positive_exonvariant?(record)
            variant = record.raw_fields['genotype']
            variant.scan(EXON_VARIANT_REGEX).size.positive?
          end

          def targeted_test?(record)
            moltesttype = record.raw_fields['moleculartestingtype']
            moltesttype.scan(/pred|conf|targeted/i).size.positive? ||
            moltesttype.scan(/BRCA(1|2) exon deletion\/duplication/i).size.positive?
          end

          def full_screen?(record)
            moltesttype = record.raw_fields['moleculartestingtype']
            moltesttype.scan(/screen/i).size.positive? ||
            moltesttype == 'BRCA1 & 2 exon deletion & duplication analysis'
          end

          def ashkenazi?(record)
            moltesttype = record.raw_fields['moleculartestingtype']
            moltesttype.scan(/ash/i).size.positive?
          end

          def polish?(record)
            moltesttype = record.raw_fields['moleculartestingtype']
            moltesttype.scan(/polish/i).size.positive?
          end

          def void_genetictestscope?(record)
            record.raw_fields['moleculartestingtype'].empty? ||
            record.raw_fields['moleculartestingtype'] == 'Store'
          end
        end
      end
    end
  end
end
