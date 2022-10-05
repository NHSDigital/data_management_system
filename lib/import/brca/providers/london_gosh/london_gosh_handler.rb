module Import
  module Brca
    module Providers
      module LondonGosh
        # BRCA extractor for London Gosh provider
        class LondonGoshHandler < Import::Germline::ProviderHandler
          PASS_THROUGH_FIELDS = %w[age consultantcode servicereportidentifier providercode
                                   authoriseddate requesteddate collecteddate
                                   receiveddate practitionercode genomicchange
                                   specimentype].freeze

          BRCA_REGEX = /(?<brca>BRCA1|
                                BRCA2|
                                BRIP1|
                                CDK4|
                                CDKN2A|
                                CHEK2|
                                MLH1|
                                MSH2|
                                MSH6|
                                PALB2|
                                PMS2|
                                PTEN|
                                RAD51C|
                                RAD51D|
                                STK11|
                                TP53)/ix.freeze

          VARIANT_PATH_CLASS = { 'pathogenic mutation' => 5,
                                 '1A' => 5,
                                 '1B' => 4,
                                 'Variant of uncertain significance' => 3,
                                 'variant requiring evaluation' => 3,
                                 '2A' => 1,
                                 '2B' => 2,
                                 '2C' => 3,
                                 'variant' => 2,
                                 '' => nil }.freeze

          TEST_TYPE_MAP = { 'affected' => :diagnostic,
                            'unaffected' => :predictive }.freeze

          CDNA_REGEX = /:?c\.(?<cdna>.+),?/i.freeze
          PROT_REGEX = /p\.(?<impact>.+)/i.freeze
          DEL_DUP_REGEX = /exon(?<s>s)?\s(?<exon>\d+(?<d>-\d+)?)\s
                          (?<deldup>Deletion|Duplication)/ix.freeze
          TRANSCRIPT_REGEX = /(?<transcript>NM.+)(?=:)/i.freeze

          def initialize(batch)
            @failed_genotype_counter = 0
            @successful_gene_counter = 0
            @failed_gene_counter = 0
            @negative_test = 0
            @positive_test = 0
            super
          end

          def process_fields(record)
            @lines_processed += 1 # TODO: factor this out to be automatic across handlers
            genotype = Import::Brca::Core::GenotypeBrca.new(record)
            genotype.add_passthrough_fields(record.mapped_fields,
                                            record.raw_fields,
                                            PASS_THROUGH_FIELDS)
            genotype.add_test_scope(:full_screen)
            add_organisationcode_testresult(genotype)
            res = process_gene_and_variant(genotype, record)
            res.map { |cur_genotype| @persister.integrate_and_store(cur_genotype) }
          end

          def add_organisationcode_testresult(genotype)
            genotype.attribute_map['organisationcode_testresult'] = '69A70'
          end

          def process_gene_and_variant(genotype, record)
            genotypes = []
            mutated_gene = record.raw_fields['gene']
            all_genes = record.raw_fields['genes analysed'] unless
                         record.raw_fields['genes analysed'].nil?
            if BRCA_REGEX.match(mutated_gene)
              negative_mutated_genes(genotype, genotypes, all_genes, mutated_gene)
              if cdna_variant?(record)
                coding_variant(record, genotype, genotypes, mutated_gene, all_genes)
              elsif exonic_variant?(record)
                exonic_variant(record, genotype, genotypes, mutated_gene, all_genes)
              end
            else
              negative_genes(genotype, genotypes, all_genes)
            end
            genotypes
          end

          def cdna_variant?(record)
            coding_cdna = record.raw_fields['codingdnasequencechange']
            acmg_cdna = record.raw_fields['acmg_cdna']

            (coding_cdna.present? && coding_cdna.scan(CDNA_REGEX).size.positive?) ||
              (acmg_cdna.present? && acmg_cdna.scan(CDNA_REGEX).size.positive?)
          end

          def exonic_variant?(record)
            return if record.raw_fields['codingdnasequencechange'].nil?

            record.raw_fields['codingdnasequencechange'].scan(DEL_DUP_REGEX).size.positive?
          end

          def negative_genes(genotype, genotypes, all_genes)
            return if all_genes.blank?

            @logger.debug('NO MUTATION FOUND')
            negative_genes = all_genes.split(';')
            process_negative_genes(negative_genes, genotype, all_genes, genotypes)
          end

          def negative_mutated_genes(genotype, genotypes, all_genes, mutated_gene)
            return if all_genes.blank?

            negative_genes = all_genes.split(';') - [mutated_gene] unless all_genes.nil?
            process_negative_genes(negative_genes, genotype, all_genes, genotypes)
          end

          def process_negative_genes(negative_genes, genotype, _all_genes, genotypes)
            @logger.debug("Negative genes are #{negative_genes}")
            negative_genes.each do |neg_gene|
              duplicated_genotype = genotype.dup
              duplicated_genotype.add_gene(neg_gene)
              duplicated_genotype.add_status(1)
              genotypes.append(duplicated_genotype)
            end
          end

          def coding_variant(record, genotype, genotypes, mutated_gene, _all_genes)
            return if record.raw_fields['codingdnasequencechange'].nil? &&
                      record.raw_fields['acmg_cdna'].nil?

            dna_variant = []
            dna_variant.append(record.raw_fields['acmg_cdna'],
                               record.raw_fields['codingdnasequencechange'])
            protein_variant = []
            protein_variant.append(record.raw_fields['acmg_protein_change'],
                                   record.raw_fields['proteinimpact'])
            mut_gene = BRCA_REGEX.match(mutated_gene)[:brca]
            mut_cdna = CDNA_REGEX.match(dna_variant.flatten.compact.uniq[0])[:cdna]
            mut_protein = PROT_REGEX.match(protein_variant.flatten.compact.uniq[0])[:impact]
            add_variants_to_genotype(genotype, record, mut_gene, mut_cdna, mut_protein)
            genotypes.append(genotype)
          end

          def exonic_variant(record, genotype, genotypes, mutated_gene, _all_genes)
            exon_record = record.raw_fields['codingdnasequencechange']
            mut_gene = BRCA_REGEX.match(mutated_gene)[:brca]
            exon_variant = DEL_DUP_REGEX.match(exon_record)[:deldup]
            exon_location = DEL_DUP_REGEX.match(exon_record)[:exon]
            genotype.add_gene(mut_gene)
            genotype.add_variant_type(exon_variant)
            genotype.add_exon_location(exon_location)
            if varpathclass_present?(record)
              genotype.add_variant_class(record.raw_fields['acmg_classification'].to_i)
            end
            extract_reference_transcript(record, genotype) if reference_transcript_present?(record)
            genotypes.append(genotype)
          end

          def varpathclass_present?(record)
            return if record.raw_fields['acmg_classification'].nil?

            record.raw_fields['acmg_classification'].present?
          end

          def reference_transcript_present?(record)
            transcript1 = record.raw_fields['codingdnasequencechange']
            transcript2 = record.raw_fields['acmg_cdna']

            (transcript1.present? && transcript1.scan(TRANSCRIPT_REGEX).size.positive?) ||
              (transcript2.present? && transcript2.scan(TRANSCRIPT_REGEX).size.positive?)
          end

          def extract_reference_transcript(record, genotype)
            transcript1 = record.raw_fields['codingdnasequencechange']
            transcript2 = record.raw_fields['acmg_cdna']
            if transcript1.present? && transcript1.scan(TRANSCRIPT_REGEX).size.positive?
              genotype.add_referencetranscriptid(TRANSCRIPT_REGEX.match(transcript1)[:transcript])
            elsif transcript2.present? && transcript2.scan(TRANSCRIPT_REGEX).size.positive?
              genotype.add_referencetranscriptid(TRANSCRIPT_REGEX.match(transcript2)[:transcript])
            end
            genotype
          end

          def add_variants_to_genotype(genotype, record, mut_gene, mut_cdna, mut_protein)
            genotype.add_gene(mut_gene)
            genotype.add_gene_location(mut_cdna)
            genotype.add_protein_impact(mut_protein)
            if varpathclass_present?(record)
              genotype.add_variant_class(record.raw_fields['acmg_classification'].to_i)
            end
            extract_reference_transcript(record, genotype) if reference_transcript_present?(record)
          end
        end
      end
    end
  end
end
