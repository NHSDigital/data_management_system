require 'possibly'
require 'pry'

module Import
  module Colorectal
    module Providers
      module LondonGosh
        # Royal Marsden Colorectal Importer
        class LondonGoshHandlerColorectal < Import::Brca::Core::ProviderHandler
          PASS_THROUGH_FIELDS_COLO = %w[age consultantcode servicereportidentifier providercode
                                        authoriseddate requesteddate collecteddate
                                        receiveddate practitionercode genomicchange
                                        specimentype].freeze

          COLORECTAL_GENES_REGEX = /(?<colorectal>APC|
                                                BMPR1A|
                                                EPCAM|
                                                MLH1|
                                                MSH2|
                                                MSH6|
                                                MUTYH|
                                                PMS2|
                                                POLD1|
                                                POLE|
                                                PTEN|
                                                SMAD4|
                                                STK11|
                                                NTHL1)/xi . freeze # Added by Francesco

          TEST_SCOPE_MAP_COLO_COLO = { 'full gene' => :full_screen,
                                       'specific mutation' => :targeted_mutation } .freeze

          VARIANT_PATH_CLASS_COLO = { 'pathogenic mutation' => 5,
                                      '1A' => 5,
                                      '1B' => 4,
                                      'Variant of uncertain significance' => 3,
                                      'variant requiring evaluation' => 3,
                                      '2A' => 1,
                                      '2B' => 2,
                                      '2C' => 3,
                                      'variant' => 2,
                                      '' => nil } .freeze

          TEST_TYPE_MAP_COLO = { 'affected' => :diagnostic,
                                 'unaffected' => :predictive } .freeze

          CDNA_REGEX = /\:c\.(?<cdna>.+)/i .freeze
          PROT_REGEX = /p\.(?<impact>.+)/i .freeze
          DEL_DUP_REGEX = /exon(s)? (?<exon>[\d]+(-[\d]+)?) (?<deldup>(Deletion|Duplication))/i .freeze

          def initialize(batch)
            @failed_genocolorectal_counter = 0
            @successful_gene_counter = 0
            @failed_gene_counter = 0
            @negative_test = 0
            @positive_test = 0
            super
          end

          def process_fields(record)
            @lines_processed += 1 # TODO: factor this out to be automatic across handlers
            genocolorectal = Import::Colorectal::Core::Genocolorectal.new(record)
            genocolorectal.add_passthrough_fields(record.mapped_fields,
                                                  record.raw_fields,
                                                  PASS_THROUGH_FIELDS_COLO)
            genocolorectal.add_test_scope(:full_screen)
            process_varpathclass(genocolorectal, record)
            add_organisationcode_testresult(genocolorectal)
            # process_gene_and_variant(genocolorectal, record)
            res = process_gene_and_variant(genocolorectal, record)
            res.map { |cur_genotype| @persister.integrate_and_store(cur_genotype) }
            # @persister.integrate_and_store(genocolorectal)
          end

          def add_organisationcode_testresult(genocolorectal)
            genocolorectal.attribute_map['organisationcode_testresult'] = '69A70'
          end

          def process_gene_and_variant(genocolorectal, record)
            genotypes = []
            mutated_gene = record.raw_fields['gene']
            all_genes = record.raw_fields['genes analysed'] unless record.raw_fields['genes analysed'].nil?
            dna_variant = record.raw_fields['acmg_cdna'] unless record.raw_fields['acmg_cdna'].nil?
            protein_variant = record.raw_fields['acmg_protein_change']
            exonic_variant = record.raw_fields['codingdnasequencechange'] unless record.raw_fields['codingdnasequencechange'].nil?
            if COLORECTAL_GENES_REGEX.match(mutated_gene)
              if CDNA_REGEX.match(dna_variant)
                coding_variant(genocolorectal, genotypes, mutated_gene, dna_variant, protein_variant, all_genes)
              elsif DEL_DUP_REGEX.match(exonic_variant)
                exonic_variant(genocolorectal, genotypes, mutated_gene, exonic_variant, all_genes)
              end
            else
              negative_genes(genocolorectal, genotypes, all_genes)
            end
            genotypes
          end

          def negative_genes(genocolorectal, genotypes, all_genes)
            if all_genes.present?
              @logger.debug('NO MUTATION FOUND')
              negative_genes = all_genes.split(';')
              process_negative_genes(negative_genes, genocolorectal, all_genes, genotypes)
            end
          end

          def negative_mutated_genes(genocolorectal, genotypes, all_genes, mutated_gene)
            if all_genes.present?
              negative_genes = all_genes.split(';') - [mutated_gene] unless all_genes.nil?
              process_negative_genes(negative_genes, genocolorectal, all_genes, genotypes)
            end
          end

          def process_negative_genes(negative_genes, genocolorectal, _all_genes, genotypes)
            @logger.debug("Negative genes are #{negative_genes}")
            negative_genes.each { |neg_gene|
              duplicated_genotype = genocolorectal.dup_colo
              duplicated_genotype.add_gene_colorectal(neg_gene)
              duplicated_genotype.add_status(1)
              genotypes.append(duplicated_genotype)
            }
          end

          def coding_variant(genocolorectal, genotypes, mutated_gene, dna_variant, protein_variant, all_genes)
            mut_gene = COLORECTAL_GENES_REGEX.match(mutated_gene)[:colorectal]
            @logger.debug("Found mutated gene #{mut_gene}")
            mut_cdna = CDNA_REGEX.match(dna_variant)[:cdna]
            mut_protein = PROT_REGEX.match(protein_variant)[:impact]
            negative_mutated_genes(genocolorectal, genotypes, all_genes, mutated_gene)
            genocolorectal.add_gene_colorectal(mut_gene)
            genocolorectal.add_gene_location(mut_cdna)
            genocolorectal.add_protein_impact(mut_protein)
            genotypes.append(genocolorectal)
          end

          def exonic_variant(genocolorectal, genotypes, mutated_gene, exonic_variant, all_genes)
            mut_gene = COLORECTAL_GENES_REGEX.match(mutated_gene)[:colorectal]
            exon_variant = DEL_DUP_REGEX.match(exonic_variant)[:deldup]
            exon_location = DEL_DUP_REGEX.match(exonic_variant)[:exon]
            @logger.debug("Found mutated gene #{mut_gene} for insertion deletion duplication")
            @logger.debug("Found mutated #{exon_variant} for insertion deletion duplication")
            @logger.debug("Found exon(s) #{exon_location} for insertion deletion duplication")
            negative_mutated_genes(genocolorectal, genotypes, all_genes, mutated_gene)
            genocolorectal.add_gene_colorectal(mut_gene)
            genocolorectal.add_variant_type(exon_variant)
            genocolorectal.add_exon_location(exon_location)
            genotypes.append(genocolorectal)
          end

          def process_varpathclass(genocolorectal, record)
            varpathclass = record.raw_fields['acmg_classification']
            if varpathclass.present?
              genocolorectal.add_variant_class(varpathclass.to_i)
              @logger.debug("Assigned varpathclass = #{varpathclass} to genotype")
            else
              @logger.debug('Impossible to assign varpathclass to genotype')
            end
          end
        end
      end
    end
  end
end
