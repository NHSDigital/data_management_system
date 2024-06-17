require 'date'

module Import
  module Colorectal
    module Providers
      module StGeorge
        # Process St George-specific record details into generalized internal genotype format
        class StGeorgeHandlerColorectal < Import::Germline::ProviderHandler
          include Import::Helpers::Colorectal::Providers::Rj7::Constants

          def process_fields(record)
            # records using new importer should only have SRIs starting with V
            return unless record.raw_fields['servicereportidentifier'].start_with?('V')

            genotype = Import::Colorectal::Core::Genocolorectal.new(record)

            # add standard passthrough fields to genotype object
            genotype.add_passthrough_fields(record.mapped_fields, record.raw_fields,
                                            PASS_THROUGH_FIELDS)

            assign_test_scope(genotype, record)
            genotypes = fill_genotypes(genotype, record)

            genotypes.each do |single_genotype|
              process_variants(single_genotype, record)

              @persister.integrate_and_store(single_genotype)
            end
          end

          def assign_test_type(genotype, record)
            # extract molecular testing type from the raw record
            # map molecular testing type and assign to genotype using
            # add_molecular_testing_type_strict method from genocolorectal.rb

            return if record.raw_fields['moleculartestingtype'].blank?

            return unless TEST_TYPE_MAP[record.raw_fields['moleculartestingtype']&.downcase&.strip]

            genotype.add_molecular_testing_type_strict(TEST_TYPE_MAP[record.raw_fields['moleculartestingtype']&.downcase&.strip])
          end

          def assign_test_scope(genotype, record)
            # extract molecular testing type from the raw record
            # map molecular testing type and assign to genotype using
            # add_test_scope method from genocolorectal.rb
            # return (filled) genotype

            testscope = record.raw_fields['moleculartestingtype']&.downcase&.strip
            genotype.add_test_scope(TEST_SCOPE_MAP[testscope])

            return genotype if genotype.attribute_map['genetictestscope'].present?

            @logger.error 'ERROR - record with no genetic test scope, ask Fiona for new rules'
          end

          def fill_genotypes(genotype, record)
            # process the genes, genotypes and test status for each gene listed in the genotype

            genes_dict = process_genes(genotype, record)
            handle_test_status(record, genotype, genes_dict)
          end

          def process_genes(genotype, record)
            # process the gene names in columns listed and check for matches with the CRC gene regex list
            # add matched tgenes to the genes_dict
            # if no matched to crc gene regex list then check for matches in CRC gene map to add to the genes_dict
            # return genes_dict
            genes_dict = {}

            columns = if genotype.targeted?
                        ['gene', 'gene (other)']
                      elsif genotype.full_screen?
                        ['gene', 'gene (other)', 'variant_dna', 'test/panel']

                      end

            columns.each do |column|
              genes = []
              gene_list = record.raw_fields[column]&.scan(CRC_GENE_REGEX)

              gene_list = process_test_panels(record, gene_list, column) if column == 'test/panel'

              next if gene_list.nil?

              gene_list.each do |gene|
                CRC_GENE_MAP[gene]&.each do |gene_value|
                  genes.append(gene_value)
                end
              end

              genes_dict[column] = genes.uniq
            end

            genes_dict
          end

          def process_test_panels(record, gene_list, column)
            # extracts panels tested from record
            # map panels to list of genes in FULL_SCREEN_TESTS_MAP
            # return list of genes tested in panel
            panel_genes_list = FULL_SCREEN_TESTS_MAP[record.raw_fields['test/panel']]
            panel_genes_list&.each do |gene|
              gene_list.append(gene)
            end

            r211 = record.raw_fields[column]&.eql?('R211')

            if r211.present?
              r211_genes = process_r211(record)
              r211_genes.each do |gene|
                gene_list.append(gene)
              end
            end

            gene_list
          end

          def process_r211(record)
            # identify genes tested on the R222 panel based on authorised date
            # return list of genes in R211 panel
            return unless record.raw_fields['test/panel'] == 'R211'

            date = DateTime.parse(record.raw_fields['authoriseddate'])
            panel_change_date = DateTime.parse('18/07/2022')
            genes = %w[APC BMPR1A EPCAM MLH1 MSH2 MSH6 MUTYH NTHL1 PMS2 POLD1 POLE PTEN SMAD4 STK11]

            date < panel_change_date ? genes : genes + %w[GREM1 RNF43]
          end

          def handle_test_status(record, genotype, genes)
            columns = if genotype.targeted?
                        ['gene', 'gene (other)']
                      elsif genotype.full_screen?

                        ['test/panel', 'gene', 'gene (other)', 'variant_dna']
                      end

            genotypes = duplicate_genotype(columns, genotype, genes, record) if columns.present?

            genotypes
          end

          def duplicate_genotype(columns, genotype, genes, record)
            # Iterates through relevant columns and runs assign_test_status method - assigns test status for each gene
            # Adds genotype to genotypes list and returns list
            genotypes = []
            columns.each do |column|
              genes[column]&.each do |gene|
                genotype_new = genotype.dup_colo
                genotype_new.add_gene_colorectal(gene)
                if genotype.full_screen?
                  assign_test_status_fullscreen(record, genotype_new, genes, column)
                elsif genotype.targeted?
                  assign_test_status_targeted(record, genotype_new, genes, column, gene)
                end
                genotypes.append(genotype_new)
              end
            end
            genotypes
          end

          def assign_test_status_targeted(record, genotype, genes, column, gene)
            # interrogate the variant dna, raw gene (other) and raw variant protein columns

            if record.raw_fields['gene (other)'].present?
              interrogate_gene_other_targeted(record, genotype, genes, column, gene)

            elsif record.raw_fields['variant dna'].present?
              interrogate_variant_dna_targeted(record, genotype, column)

            elsif record.raw_fields['variant protein'].present?
              interrogate_variant_protein_targeted(record, genotype, column)

            else
              genotype.add_status(1)

            end
          end

          def interrogate_gene_other_targeted(record, genotype, _genes, column, _gene)
            # Match the data in the raw 'gene (other)' field to the relevant regular expression
            # Assign the appropriate test status
            # Else, interogate the variant dna column
            if record.raw_fields['gene (other)'].match(/^Fail|^Blank\scontamination$/ix)
              genotype.add_status(9)
            elsif record.raw_fields['gene (other)'].match(/^het|del|dup|^c./ix)
              genotype.add_status(2)
            else
              interrogate_variant_dna_targeted(record, genotype, column)
            end
          end

          def interrogate_variant_dna_targeted(record, genotype, column)
            # Match the data in the raw 'variant dna' field to the relevant regular expression
            # Assign the appropriate test status
            # Else, interogate the variant protein column
            if record.raw_fields['variant dna'].match(/Fail|^Blank\scontamination$/ix)
              genotype.add_status(9)
            elsif record.raw_fields['variant dna'].match(%r{^Normal|^no\sdel/dup$}ix)
              genotype.add_status(1)
            elsif record.raw_fields['variant dna'].match(/SNP\spresent$|see\scomments/ix)
              genotype.add_status(4)
            elsif record.raw_fields['variant dna'].match \
              (/het\sdel|het\sdup|het\sinv|^ex.*del|^ex.*dup|^ex.*inv|^del\sex|^dup\sex|^inv\sex|^c\./ix)
              genotype.add_status(2)
            else
              interrogate_variant_protein_targeted(record, genotype, column)

            end
          end

          def interrogate_variant_protein_targeted(record, genotype, column)
            # Match the data in the raw 'variant protein' field to the relevant regular expression
            # Assign the appropriate test status
            # Else, add test status of 1
            if record.raw_fields['variant protein'].match(/^p\./ix)
              update_status(2, 1, column, ['gene', 'gene (other)'], genotype)
            elsif record.raw_fields['variant protein'].match(/fail/ix)
              genotype.add_status(9)
            else
              genotype.add_status(1)
            end
          end

          def assign_test_status_fullscreen(record, genotype, genes, column)
            # interrogate the variant dna column and raw gene (other) column

            if record.raw_fields['variant dna'].present?
              interrogate_variant_dna_fullscreen(record, genotype, genes, column)
            elsif record.raw_fields['variant protein'].present?
              interrogate_variant_protein_fullscreen(record, genotype, column)
            else
              genotype.add_status(1)
            end
          end

          def interrogate_variant_dna_fullscreen(record, genotype, genes, column)
            variant_regex = \
              /het\sdel|het\sdup|het\sinv|^ex.*del|^ex.*dup|^ex.*inv|^del\sex|^dup\sex|^inv\sex|^c\.|^inversion$/ix

            if record.raw_fields['variant dna'].match(/Fail/ix)
              genotype.add_status(9)
            elsif record.raw_fields['variant dna'] == 'N' || record.raw_fields['variant dna'].blank?
              genotype.add_status(1)
            elsif record.raw_fields['variant dna'].match(variant_regex) && record.raw_fields['gene'].present?
              update_status(2, 1, column, ['gene'], genotype)
            elsif record.raw_fields['variant dna'].match(variant_regex) \
              && record.raw_fields['gene'].blank? \
                && genes['gene (other)'].length == 1
              update_status(2, 1, column, ['gene (other)'], genotype)
            elsif record.raw_fields['variant dna'].match(variant_regex) \
                && record.raw_fields['gene'].blank? \
                  && (genes['gene (other)'].blank? || genes['gene (other)'].length > 1)
              # Gene should be specified in raw:variant dna; assign 2 (abnormal) for the specified gene and
              # 1 (normal) for all other genes.
              update_status(2, 1, column, ['variant dna'], genotype)
            else
              interrogate_variant_protein_fullscreen(record, genotype, column)

            end
          end

          def interrogate_variant_protein_fullscreen(record, genotype, column)
            if record.raw_fields['variant protein'].blank?
              genotype.add_status(1)
            elsif record.raw_fields['variant protein'].match(/p.*/ix)
              update_status(2, 1, column, ['gene', 'gene (other)'], genotype)
            elsif record.raw_fields['variant protein'].match(/fail/ix)
              genotype.add_status(9)
            else
              genotype.add_status(1)
            end
          end

          def update_status(status1, status2, column, column_name, genotype)
            # update genotype status depending on if the gene is in the same column that the rule applies to

            if column_name.include? column
              genotype.add_status(status1)
            else
              genotype.add_status(status2)
            end
          end

          def process_variants(genotype, record)
            # add hgvsc and hgvsp codes - if not present then run process_location_type_zygosity
            return unless genotype.attribute_map['teststatus'] == 2

            if /c\.(?<cdna>.*)/i.match(record.raw_fields['variant dna'])
              genotype.add_gene_location($LAST_MATCH_INFO[:cdna])
            end
            if /p\.(?<impact>.*)/i.match(record.raw_fields['variant protein'])
              genotype.add_protein_impact($LAST_MATCH_INFO[:impact])
            end

            if record.mapped_fields['codingdnasequencechange'].blank? && record.mapped_fields['proteinimpact'].blank?
              process_location_type(genotype, record)
            end
          end

          def process_location_type(genotype, record)
            # use methods in genotype.rb to add exon location, variant type and zygosity
            # all current evidence is in variant dna column - future proofing with gene (other) column as well
            ['variant dna', 'gene (other)'].each do |column|
              next unless EXON_REGEX.match(record.raw_fields[column])

              genotype.add_exon_location($LAST_MATCH_INFO[:exons])
              genotype.add_variant_type($LAST_MATCH_INFO[:mutationtype])
            end
          end
        end
      end
    end
  end
end
