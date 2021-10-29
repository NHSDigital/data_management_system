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
                                   providercode receiveddate sampletype].freeze
          CDNA_REGEX = /c\.(?<cdna>[0-9]+[^\s)]+)|c\.\[(?<cdna>.*?)\]/i.freeze

          PROTEIN_REGEX = /p\.(?<impact>[a-z]+[0-9]+[a-z]+)|
                           p\.(?<sqrbo>\[)?(?<rndbo>\()?(?<impact>[a-z]+[0-9]+[a-z]+)
                           (?<rndbrc>\))?(?<sqrbc>\])?/ix.freeze

          DEPRECATED_BRCA_NAMES_MAP = { 'BR1'    => 'BRCA1',
                                        'B1'     => 'BRCA1',
                                        'BRCA 1' => 'BRCA1',
                                        'BR2'    => 'BRCA2',
                                        'B2'     => 'BRCA2',
                                        'BRCA 2' => 'BRCA2' }.freeze

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

          EXON_VARIANT_REGEX = /(?<variant>del|dup|ins).+ex(?<on>on)?(?<s>s)?\s
                                (?<exons>[0-9]+(?<dgs>-[0-9]+)?)|
                              ex(?<on>on)?(?<s>s)?\s(?<exons>[0-9]+(?<dgs>-[0-9]+)?)\s
                              (?<variant>del|dup|ins)|
                              (?<variant>del|dup|ins)\sexon(?<s>s)?\s
                              (?<exons>[0-9]+(?<dgs>\sto\s[0-9]+))|
                              (?<variant>del|dup|ins)(?<s>\s)?(?<exons>[0-9]+(?<dgs>-[0-9]+)?)|
                              ex(?<on>on)?(?<s>s)?\s(?<exons>[0-9]+(?<dgs>\sto\s[0-9]+)?)\s
                              (?<variant>del|dup|ins)/ix.freeze

          DEPRECATED_BRCA_NAMES_REGEX = /B1|BR1|BRCA\s1|B2|BR2|BRCA\s2/i.freeze

          DELIMETER_REGEX = /[&\n+,;]|and|IFD/i.freeze

          def process_fields(record)
            genotype = Import::Brca::Core::GenotypeBrca.new(record)
            genotype.add_passthrough_fields(record.mapped_fields,
                                            record.raw_fields,
                                            PASS_THROUGH_FIELDS)
            add_organisationcode_testresult(genotype)
            add_moleculartestingtype(genotype, record)
            process_genetictestcope(genotype, record)
            res = process_variants_from_record(genotype, record)
            res.each { |cur_genotype| @persister.integrate_and_store(cur_genotype) }
          end

          def add_organisationcode_testresult(genotype)
            genotype.attribute_map['organisationcode_testresult'] = '697N0'
          end

          def add_moleculartestingtype(genotype, record)
            return if record.raw_fields['moleculartestingtype'].nil?

            moltesttype = record.raw_fields['moleculartestingtype']
            if moltesttype.scan(/unaf|pred/i).size.positive?
              genotype.add_molecular_testing_type_strict(:predictive)
            elsif moltesttype.scan(/affected|conf/i).size.positive?
              genotype.add_molecular_testing_type_strict(:diagnostic)
            end
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
              @logger.debug 'Unknown moleculartestingtype'
            end
          end

          def process_variants_from_record(genotype, record)
            genotypes = []
            positive_gene = get_positive_genes(record)
            if ashkenazi?(record) || polish?(record) || full_screen?(record)
              process_fullscreen_records(genotype, record, positive_gene, genotypes)
            elsif targeted_test?(record) || void_genetictestscope?(record)
              process_targeted_records(positive_gene, genotype, record, genotypes)
            end
            genotypes
          end

          def get_positive_genes(record)
            positive_gene = []
            gene = record.raw_fields['genotype'].scan(BRCA_GENES_REGEX)
            deprecated_gene = record.raw_fields['genotype'].scan(DEPRECATED_BRCA_NAMES_REGEX)
            process_rightname_gene(gene, positive_gene) if gene.present?
            process_deprecated_gene(deprecated_gene, positive_gene) if deprecated_gene.present?
            @logger.debug 'Unable to extract gene' if gene.empty? && deprecated_gene.empty?
            positive_gene
          end

          def process_rightname_gene(gene, positive_genes)
            gene.size == 1 ? positive_genes.append(gene.join) : positive_genes.append(gene)
          end

          def process_deprecated_gene(deprecated_gene, positive_genes)
            if deprecated_gene.size == 1
              positive_genes.append(DEPRECATED_BRCA_NAMES_MAP[deprecated_gene.join])
            else
              deprecated_gene.each do |dg|
                positive_genes.append(DEPRECATED_BRCA_NAMES_MAP[dg])
              end
            end
          end

          def process_fullscreen_records(genotype, record, positive_genes, genotypes)
            if normal?(record)
              normal_full_screen(genotype, genotypes)
            elsif failed_test?(record)
              failed_full_screen(genotype, genotypes)
            elsif positive_cdna?(record) || positive_exonvariant?(record)
              if record.raw_fields['genotype'].scan(CDNA_REGEX).size > 1
                process_multiple_positive_variants(positive_genes, genotype, record, genotypes)
              else
                single_variant_full_screen(genotype, genotypes, positive_genes, record)
              end
            end
            genotypes
          end

          def normal_full_screen(genotype, genotypes)
            %w[BRCA1 BRCA2].each do |negative_gene|
              genotype_dup = genotype.dup
              genotype_dup.add_gene(negative_gene)
              genotype_dup.add_status(1)
              genotypes.append(genotype_dup)
            end
          end

          def failed_full_screen(genotype, genotypes)
            %w[BRCA1 BRCA2].each do |negative_gene|
              genotype_dup = genotype.dup
              genotype_dup.add_gene(negative_gene)
              genotype_dup.add_status(9)
              genotypes.append(genotype_dup)
            end
          end

          def single_variant_full_screen(genotype, genotypes, positive_genes, record)
            negative_gene = %w[BRCA1 BRCA2] - positive_genes
            genotype_dup = genotype.dup
            genotype_dup.add_gene(negative_gene.join)
            genotype_dup.add_status(1)
            genotypes.append(genotype_dup)
            genotype.add_gene(positive_genes.join)
            process_single_positive_variants(genotype, record)
            process_single_protein(genotype, record)
            genotypes.append(genotype)
          end

          def process_targeted_records(positive_genes, genotype, record, genotypes)
            if normal?(record)
              process_normal_targeted(genotype, record, genotypes)
            elsif failed_test?(record)
              process_failed_targeted(genotype, record, genotypes)
            elsif positive_cdna?(record) || positive_exonvariant?(record)
              process_positive_targeted(record, positive_genes, genotype, genotypes)
            end
            genotypes
          end

          def process_normal_targeted(genotype, record, genotypes)
            process_single_gene(genotype, record)
            genotype.add_status(1)
            genotypes.append(genotype)
          end

          def process_failed_targeted(genotype, record, genotypes)
            process_single_gene(genotype, record)
            genotype.add_status(9)
            genotypes.append(genotype)
          end

          def process_positive_targeted(record, positive_genes, genotype, genotypes)
            if record.raw_fields['genotype'].scan(CDNA_REGEX).size > 1
              process_multiple_positive_variants(positive_genes, genotype, record, genotypes)
            else
              process_single_gene(genotype, record)
              process_single_positive_variants(genotype, record)
              process_single_protein(genotype, record)
              genotypes.append(genotype)
            end
          end

          # Ordering here is important so duplicate branches are required
          # rubocop:disable  Lint/DuplicateBranch
          def process_single_gene(genotype, record)
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
            else
              @logger.debug "FAILED gene parse for: #{record.raw_fields['genotype']}"
            end
          end
          # rubocop:enable  Lint/DuplicateBranch

          def process_single_protein(genotype, record)
            if record.raw_fields['genotype'].scan(PROTEIN_REGEX).size.positive?
              genotype.add_protein_impact($LAST_MATCH_INFO[:impact])
              @logger.debug "SUCCESSFUL gene parse for: #{$LAST_MATCH_INFO[:impact]}"
            else
              @logger.debug "FAILED protein parse for: #{record.raw_fields['genotype']}"
            end
          end

          def process_single_positive_variants(genotype, record)
            if positive_cdna?(record)
              process_cdna_variant(genotype, record)
            elsif positive_exonvariant?(record)
              process_exonic_variant(genotype, record)
            else
              @logger.debug "FAILED variant parse for: #{record.raw_fields['genotype']}"
            end
          end

          def add_variants_multiple_results(variants, genotype, genotypes)
            variants.each do |gene, mutation, protein|
              genotype_dup = genotype.dup
              genotype_dup.add_gene(gene)
              genotype_dup.add_gene_location(mutation)
              genotype_dup.add_protein_impact(protein)
              genotype_dup.add_status(2)
              genotypes.append(genotype_dup)
            end
          end

          def process_multiple_positive_variants(positive_genes, genotype, record, genotypes)
            if positive_genes.flatten.uniq.size > 1
              variants = process_multi_genes_rec(record, positive_genes)
            elsif positive_genes.flatten.uniq.size == 1
              variants = process_uniq_gene_rec(record, positive_genes)
            end

            add_variants_multiple_results(variants, genotype, genotypes) unless variants.nil?

            genotypes
          end

          def process_multi_genes_rec(record, positive_genes)
            if record.raw_fields['genotype'].scan(DELIMETER_REGEX).size > 1
              variants = process_single_variant(record, positive_genes)
            elsif record.raw_fields['genotype'].scan(DELIMETER_REGEX).size.positive?
              variants = process_split_variants(record, [])
            end
            variants
          end

          def process_uniq_gene_rec(record, positive_genes)
            if record.raw_fields['genotype'].scan(DELIMETER_REGEX).size.positive?
              variants = process_split_variants(record, positive_genes)
            else
              positive_genes *= record.raw_fields['genotype'].scan(CDNA_REGEX).
                                flatten.compact.size
              variants = process_single_variant(record, positive_genes)
            end
            variants
          end

          def process_single_variant(record, positive_genes)
            mutation = get_cdna_mutation(record.raw_fields['genotype'])
            protein = get_protein_impact(record.raw_fields['genotype'])
            positive_genes.zip(mutation, protein.flatten.compact)
          end

          def process_split_variants(record, positive_genes)
            record.raw_fields['genotype'].scan(DELIMETER_REGEX)
            raw_genotypes = record.raw_fields['genotype'].split($LAST_MATCH_INFO[0])
            variants = []
            raw_genotypes.each do |raw_genotype|
              if positive_genes == []
                positive_gene_rec = []
                gene = raw_genotype.scan(BRCA_GENES_REGEX)
                deprec_gene = raw_genotype.scan(DEPRECATED_BRCA_NAMES_REGEX)
                process_rightname_gene(gene, positive_gene_rec) if gene.present?
                process_deprecated_gene(deprec_gene, positive_gene_rec) if deprec_gene.present?
              else
                positive_gene_rec = positive_genes
              end
              mutation = get_cdna_mutation(raw_genotype)
              protein = get_protein_impact(raw_genotype)
              variants << positive_gene_rec.zip(mutation, protein.flatten.compact).flatten
            end
            variants
          end

          def get_protein_impact(raw_genotype)
            raw_genotype.scan(PROTEIN_REGEX)
            $LAST_MATCH_INFO.nil? ? [] : [$LAST_MATCH_INFO[:impact]]
          end

          def get_cdna_mutation(raw_genotype)
            raw_genotype.scan(CDNA_REGEX).flatten.compact
          end

          def add_gene_from_deprecated_nomenclature(genotype, record)
            genename = record.raw_fields['genotype'].scan(DEPRECATED_BRCA_NAMES_REGEX).flatten.uniq
            genotype.add_gene(DEPRECATED_BRCA_NAMES_MAP[genename.join])
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
            return unless record.raw_fields['genotype'].scan(EXON_VARIANT_REGEX).size.positive?

            genotype.add_exon_location($LAST_MATCH_INFO[:exons])
            genotype.add_variant_type($LAST_MATCH_INFO[:variant])
            genotype.add_status(2)
            @logger.debug "SUCCESSFUL exon variant parse for: #{record.raw_fields['genotype']}"
            # end
          end

          def process_cdna_variant(genotype, record)
            return unless record.raw_fields['genotype'].scan(CDNA_REGEX).size.positive?

            genotype.add_gene_location($LAST_MATCH_INFO[:cdna])
            genotype.add_status(2)
            @logger.debug "SUCCESSFUL cdna change parse for: #{$LAST_MATCH_INFO[:cdna]}"
            # end
          end

          def process_normal_record(genotype, record)
            genotype.add_status(1)
            @logger.debug "SUCCESSFUL cdna change parse for: #{record.raw_fields['genotype']}"
          end

          def normal?(record)
            variant = record.raw_fields['genotype']
            moltesttype = record.raw_fields['moleculartestingtype']
            variant.scan(%r{NO PATHOGENIC|Normal|N/N|NOT DETECTED}i).size.positive? ||
              variant == 'N' || moltesttype.scan(/unaffected/i).size.positive?
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
            return if record.raw_fields['moleculartestingtype'].nil?

            moltesttype = record.raw_fields['moleculartestingtype']
            moltesttype.scan(/pred|conf|targeted|c\.|6174delT/i).size.positive? ||
              moltesttype.scan(%r{BRCA(1|2) exon deletion/duplication}i).size.positive?
          end

          def full_screen?(record)
            return if record.raw_fields['moleculartestingtype'].nil?

            moltesttype = record.raw_fields['moleculartestingtype']
            moltesttype.scan(/screen/i).size.positive? ||
              moltesttype == 'BRCA1 & 2 exon deletion & duplication analysis'
          end

          def ashkenazi?(record)
            return if record.raw_fields['moleculartestingtype'].nil?

            moltesttype = record.raw_fields['moleculartestingtype']
            moltesttype.scan(/ash/i).size.positive?
          end

          def polish?(record)
            return if record.raw_fields['moleculartestingtype'].nil?

            moltesttype = record.raw_fields['moleculartestingtype']
            moltesttype.scan(/polish/i).size.positive?
          end

          def failed_test?(record)
            record.raw_fields['genotype'].scan(/Fail/i).size.positive?
          end

          def void_genetictestscope?(record)
            return if record.raw_fields['moleculartestingtype'].nil?

            record.raw_fields['moleculartestingtype'].empty? ||
              record.raw_fields['moleculartestingtype'] == 'Store'
          end
        end
      end
    end
  end
end
