require 'possibly'
require 'date'

module Import
  module Brca
    module Providers
      module StGeorge
        # Process St George-specific record details into generalized internal genotype format
        class StGeorgeHandler < Import::Germline::ProviderHandler
          include Import::Helpers::Brca::Providers::Rj7::Constants

          def process_fields(record)
            return unless record.raw_fields['servicereportidentifier'].start_with?('V')

            genotype = Import::Brca::Core::GenotypeBrca.new(record)
            # records using new importer should only have SRIs starting with V

            genotype.add_passthrough_fields(record.mapped_fields, record.raw_fields, PASS_THROUGH_FIELDS)
            assign_test_type(genotype, record)
            genotype = assign_test_scope(genotype, record)

            genotypes = fill_genotypes(genotype, record)

            genotypes.each do |single_genotype|
              process_variants(single_genotype, record)
              @persister.integrate_and_store(single_genotype)
            end
            genotypes
          end

          def fill_genotypes(genotype, record)
            genotypes = []
            if genotype.targeted?
              # determines the genes in the record and creates a genotype for each one
              genes = process_genes_targeted(record)
              # For each gene in the list of genes a new genotype will need to be created
              genotypes = duplicate_genotype_targeted(genes, genotype)
              genotypes.each do |single_genotype|
                assign_test_status_targeted(single_genotype, record)
              end
            elsif genotype.full_screen?
              genes_dict = process_genes_full_screen(record)
              genotypes = handle_test_status_full_screen(record, genotype, genes_dict)
            end
            genotypes
          end

          def assign_test_type(genotype, record)
            # extract molecular testing type from the raw record
            # map molecular testing type and assign to genotype using
            # add_molecular_testing_type method from genotype.rb

            return if record.raw_fields['moleculartestingtype'].blank?

            return unless TEST_TYPE_MAP[record.raw_fields['moleculartestingtype']&.downcase&.strip]

            genotype.add_molecular_testing_type(TEST_TYPE_MAP[record.raw_fields['moleculartestingtype']&.downcase&.strip])
          end

          def assign_test_scope(genotype, record)
            # extract molecular testing type from the raw record
            # map molecular testing type and assign to genotype using
            # add_test_scope method from genotype_brca.rb
            testscope = record.raw_fields['moleculartestingtype']&.downcase&.strip
            genotype.add_test_scope(TEST_SCOPE_MAP[testscope])
            return genotype if genotype.attribute_map['genetictestscope'].present?

            genotype.add_test_scope(:no_genetictestscope)
            @logger.error 'ERROR - record with no genetic test scope, ask Fiona for new rules'
            genotype
          end

          def process_genes_targeted(record)
            # For targeted tests only
            # This method creates a list of genes included in the record that match BRCA_GENE_REGEX
            # The genotype is duplicated for each gene in this list
            # A list of genotypes (one for each gene) is returned

            columns = ['gene', 'gene (other)']
            genes = []
            columns.each do |column|
              gene_list = record.raw_fields[column]&.scan(BRCA_GENE_REGEX)
              next if gene_list.blank?

              gene_list.each do |gene|
                gene = BRCA_GENE_MAP[gene]
                genes.append(gene)
              end
            end
            genes
          end

          def duplicate_genotype_targeted(genes, genotype)
            # When there is more than one gene listed a separate genotype needs to be created for each one
            # The genotype is duplicated and the new gene is added to the duplicated genotype
            # Each genotype is then added to the genoytypes list which this method then returns
            genotypes = []
            genes.flatten.compact_blank.uniq.each do |gene_value|
              genotype_new = genotype.dup
              genotype_new.add_gene(gene_value)
              genotypes.append(genotype_new)
            end
            genotypes
          end

          def assign_test_status_targeted(genotype, record)
            # loop through list of dictionaries in TARGETED_TEST_STATUS from constants.rb
            # run assign_test_status_targeted_support for each dictionary with the values

            status = nil
            # from the dictionary forming the parameters

            TARGETED_TEST_STATUS.each do |test_values|
              if record.raw_fields[test_values[:column]].present? &&
                 record.raw_fields[test_values[:column]].scan(test_values[:expression]).size.positive?
                status = test_values[:status]
              end
              break unless status.nil?
            end

            status = 4 if status.nil? && record.raw_fields['variant protein'].blank?

            genotype.add_status(status)
          end

          def process_genes_full_screen(record)
            # extracts genes from colunns in record
            # outputs a dictionary of genes assigned to each column name
            genes_dict = {}

            ['gene', 'gene (other)', 'variant dna', 'test/panel'].each do |column|
              genes = []
              gene_list = record.raw_fields[column]&.scan(BRCA_GENE_REGEX)

              gene_list = process_test_panels(record, gene_list, column) if column == 'test/panel'

              next if gene_list.nil?

              gene_list.each do |gene|
                BRCA_GENE_MAP[gene]&.each do |gene_value|
                  genes.append(gene_value)
                end
              end

              # handles brca1 and brca2 being matched twice in one column
              genes_dict[column] = genes.uniq
            end
            genes_dict
          end

          def process_test_panels(record, gene_list, column)
            # extracts panels tested from record
            # panels mapped to list of genes in FULL_SCREEN_TESTS_MAP
            # to output list of genes tested in panel
            panel_genes_list = FULL_SCREEN_TESTS_MAP[record.raw_fields['test/panel']]

            panel_genes_list&.each do |gene|
              gene_list.append(gene)
            end
            r208 = record.raw_fields[column]&.eql?('R208')
            if r208.present?
              r208_genes = process_r208(record)
              r208_genes.each do |gene|
                gene_list.append(gene)
              end
            end
            # gene_list=process_r208(record) unless r208.blank?
            gene_list
          end

          def process_r208(record)
            # Determine genes tested from r208 panel based on the authorised date
            # output list of genes in r208 panel
            return unless record.raw_fields['test/panel'] == 'R208'

            date = DateTime.parse(record.raw_fields['authoriseddate'])
            if date < DateTime.parse('01/08/2022')
              r208_panel_genes = %w[BRCA1 BRCA2]
            elsif DateTime.parse('31/07/2022') < date && date < DateTime.parse('16/11/2022')
              r208_panel_genes = %w[BRCA1 BRCA2 CHEK2 PALB2 ATM]
            elsif date > DateTime.parse('16/11/2022')
              r208_panel_genes = %w[BRCA1 BRCA2 CHEK2 PALB2 ATM RAD51C RAD51D]
            end
            r208_panel_genes
          end

          def handle_test_status_full_screen(record, genotype, genes)
            # Creates a duplicate genotype for each gene
            # Link to assign_test_status_full screen which assigns test status for each gene
            # Adds genotype to genotype list which is then outputted
            genotypes = []
            columns = ['gene', 'gene (other)', 'variant dna', 'test/panel']
            columns.each do |column|
              genes[column]&.each do |gene|
                genotype_new = genotype.dup
                genotype_new.add_gene(gene)
                assign_test_status_full_screen(record, gene, genes, genotype_new, column)
                genotypes.append(genotype_new)
              end
            end
            genotypes
          end

          def assign_test_status_full_screen(record, gene, genes, genotype, column)
            # interrogate variant dna column
            if record.raw_fields['variant dna'].present?
              interrogate_variant_dna_column(record, genotype, genes, column, gene)
            # interrogate raw gene (other)
            elsif /fail/i.match(record.raw_fields['gene (other)']).present?
              return if match_fail(gene, record, genotype)

              update_status(10, 1, column, 'gene', genotype)
            elsif record.raw_fields['gene (other)']&.match(/\?\z/ix)
              genotype.add_status(4)
            elsif record.raw_fields['gene (other)']&.match(/^c\.|^Ex.*Del\z|^Ex.*Dup\z|^Het\sDel|^Het\sDup/ix)
              update_status(2, 1, column, 'gene', genotype)
            else
              genotype.add_status(4)

              gene_classv_gene_n_format(record, genotype, gene)
            end
          end

          def interrogate_variant_dna_column(record, genotype, genes, column, gene)
            # For full screen tests only- add test status when variant dna column is not empty
            if record.raw_fields['variant dna'].match(/Fail/ix)
              genotype.add_status(9)
            elsif record.raw_fields['variant dna'] == 'N'
              genotype.add_status(1)
            # variant dna is not '*Fail*', 'N' or null AND raw:gene is not null AND raw:gene (other) is null
            # 2 (abnormal) for gene in raw:gene. 1 (normal) for all other genes.
            elsif record.raw_fields['gene'].present? &&
                  record.raw_fields['gene (other)'].blank?
              update_status(2, 1, column, 'gene', genotype)
            # variant dna is not '*Fail*', 'N' or null AND raw:gene is not null AND raw:gene (other) is not null
            # 2 (abnormal) for gene in raw:gene.
            # 9 (failed, genetic test) for any gene specified WITH 'Fail' in raw:gene (other).
            # 1 (normal) for all other genes
            elsif record.raw_fields['gene'].present? &&
                  record.raw_fields['gene (other)'].present?
              if column == 'gene'
                genotype.add_status(2)
              elsif column == 'gene (other)'
                match_fail(gene, record, genotype)
              else
                genotype.add_status(1)
              end
            # variant dna not '*Fail*', 'N' or null AND raw:gene is null AND raw:gene(other) not a single gene
            # If gene is specified in raw:variant dna, assign 2 (abnormal) for that gene and 1 (normal) for
            # all other genes.
            # Else interrogate raw:gene (other).
            elsif record.raw_fields['gene'].blank? &&
                  (genes['gene (other)'].blank? || genes['gene (other)'].length > 1) &&
              update_status(2, 1, column, 'variant dna', genotype)
            # variant dna is not '*Fail*', 'N' or null AND raw:gene is null AND raw:gene (other) specifies a single gene
            # 2 (abnormal) for gene in raw:gene (other). 1 (normal) for all other genes.
            elsif record.raw_fields['gene'].blank? && !genes['gene (other)'].nil? && genes['gene (other)'].length == 1
              update_status(2, 1, column, 'gene (other)', genotype)
            end
          end

          def match_fail(gene, record, genotype)
            # Determines if a gene in the gene (other) column has failed
            # Assigns genes that have failed a test status of 9, otherwise teststatus is 1
          
            gene_list = record.raw_fields['gene (other)'].scan(BRCA_GENE_REGEX)
            return false if gene_list.empty?
          
            gene_list.each do |gene_value|
              mapped_gene_values = BRCA_GENE_MAP[gene_value] || []
          
              mapped_gene_values.each do |value|
                if value == gene
                  status = /#{gene_value}\s?\(?fail\)?/i.match?(record.raw_fields['gene (other)']) ? 9 : 1
                  genotype.add_status(status)
                end
              end
            end
          
            true
          end

          def update_status(status1, status2, column, column_name, genotype)
            # update genotype status depending on if the gene is in the same column that the rule applies to

            if column == column_name
              genotype.add_status(status1)
            else
              genotype.add_status(status2)
            end
          end

          def gene_classv_gene_n_format(record, genotype, gene)
            # update status of genes listed in format '[gene 1] Class V, [gene 2] N'
            # 2 (abnormal) for [gene 1]. 1 (normal) for [gene 2]
            gene_list = record.raw_fields['gene (other)']&.scan(BRCA_GENE_REGEX)
            return if gene_list.blank? || gene_list.length <= 1

            gene_list.each do |gene1|
              gene_list.each do |gene2|
                next unless /^#{gene1}\sClass\sV,\s#{gene2}\sN\z/i.match(record.raw_fields['gene (other)'])

                gene1 = BRCA_GENE_MAP[gene1]
                gene2 = BRCA_GENE_MAP[gene2]
                if gene1.include?(gene)
                  genotype.add_status(2)
                elsif gene2.include?(gene)
                  genotype.add_status(1)
                end
              end
            end
          end

          def process_variants(genotype, record)
            # add hgvsc and hgvsp codes - if not present then run process_location_type
            return unless genotype.attribute_map['teststatus'] == 2

            ['variant dna', 'gene (other)'].each do |column|
              genotype.add_gene_location($LAST_MATCH_INFO[:cdna]) if /c\.(?<cdna>.*)/i.match(record.raw_fields[column])
            end

            ['variant protein', 'variant dna', 'gene (other)'].each do |column|
              if /p\.(?<impact>.*)/.match(record.raw_fields[column])
                genotype.add_protein_impact($LAST_MATCH_INFO[:impact])
              end
            end
            if record.mapped_fields['codingdnasequencechange'].blank? && record.mapped_fields['proteinimpact'].blank?
              process_location_type(genotype, record)
            end
          end

          def process_location_type(genotype, record)
            # use methods in genotype.rb to add exon location, variant type

            record_gene= genotype.attribute_map['gene']

            ['variant dna', 'gene (other)'].each do |column|
              next unless EXON_REGEX.match(record.raw_fields[column])
              gene_list = record.raw_fields[column]&.scan(BRCA_GENE_REGEX)
              gene_list.each do |gene|
                next if gene_list.blank?
                gene = BRCA_GENE_MAP[gene][0]
                gene_integer= BRCA_INTEGER_MAP[gene]
                if gene_integer!=record_gene
                  genotype.add_status(1)
                end
              end
              if genotype.attribute_map['teststatus'] == 2
                EXON_REGEX.match(record.raw_fields[column])
                genotype.add_exon_location($LAST_MATCH_INFO[:exons])
                genotype.add_variant_type($LAST_MATCH_INFO[:mutationtype])
              end
            end
          end
        end
      end
    end
  end
end
