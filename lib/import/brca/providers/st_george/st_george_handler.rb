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
              duplicate_genotype_targeted(genes, genotype, genotypes)
              genotypes.each do |single_genotype|
                assign_test_status_targeted(single_genotype, record)
              end
            elsif genotype.full_screen?
              genes = process_genes_full_screen(record)
              assign_test_status_full_screen(record, genes, genotype, genotypes)
            end
            genotypes
          end

          def assign_test_type(genotype, record)
            # extract molecular testing type from the raw record
            # map molecular testing type and assign to genotype using
            # add_molecular_testing_type method from genotype.rb

            return if record.raw_fields['moleculartestingtype'].blank?

            raw_moleculartestingtype = record.raw_fields['moleculartestingtype'].downcase.strip

            return unless TEST_TYPE_MAP[raw_moleculartestingtype]

            genotype.add_molecular_testing_type(TEST_TYPE_MAP[raw_moleculartestingtype])
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

          def duplicate_genotype_targeted(genes, genotype, genotypes)
            # When there is more than one gene listed a separate genotype needs to be created for each one
            # The genotype is duplicated and the new gene is added to the duplicated genotype
            # Each genotype is then added to the genoytypes list which this method then returns
            genes.flatten.compact_blank.uniq.each do |gene_value|
              genotype_new = genotype.dup
              genotype_new.add_gene(gene_value)
              genotypes.append(genotype_new)
            end
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

          def assign_test_status_full_screen(record, genes, genotype, genotypes)
            @all_genes = genes.values.compact_blank.flatten.uniq

            return if @all_genes.empty?

            if record.raw_fields['variant dna'].present?
              assign_status_on_variant_dna(record, genes, genotype, genotypes)
            elsif record.raw_fields['gene (other)'].present?
              assign_status_on_gene_other(record, genes, genotype, genotypes)
            else
              process_status_genes(genotype, 4, @all_genes, genotypes)
            end
          end

          def process_status_genes(genotype, status, genes, genotypes)
            genes.each do |gene|
              genotype_new = genotype.dup
              genotype_new.add_gene(gene)
              genotype_new.add_status(status)
              genotypes << genotype_new
            end
          end

          def assign_status_on_variant_dna(record, genes, genotype, genotypes)
            variant_dna = record.raw_fields['variant dna']
            gene_other = record.raw_fields['gene (other)']
            @gene_other_brca_size = gene_other&.scan(BRCA_GENE_REGEX)&.size || 0
            case variant_dna
            when /Fail/i
              process_status_genes(genotype, 9, @all_genes, genotypes)
            when 'N'
              process_status_genes(genotype, 1, @all_genes, genotypes)
            else
              handle_gene_conditions(genes, genotype, genotypes, record)
            end
          end

          def handle_gene_conditions(genes, genotype, genotypes, record)
            gene = record.raw_fields['gene']
            gene_other = record.raw_fields['gene (other)']
            if gene.present? && gene_other.blank?
              process_genes(genes, genotype, genotypes)
            elsif gene.present? && gene_other.present?
              process_genes_with_other(gene_other, genes, genotype, genotypes)
            elsif gene.blank? && gene_other.present?
              process_other_gene(genes, genotype, genotypes, record)
            else
              process_status_genes(genotype, 4, @all_genes, genotypes)
            end
          end

          def process_genes(genes, genotype, genotypes)
            pos_gene = genes['gene']
            process_status_genes(genotype, 2, pos_gene, genotypes)
            remaining_genes = @all_genes - pos_gene
            process_status_genes(genotype, 1, remaining_genes, genotypes)
          end

          def process_genes_with_other(gene_other, genes, genotype, genotypes)
            pos_gene = genes['gene']
            process_status_genes(genotype, 2, pos_gene, genotypes)
            remaining_genes = @all_genes - pos_gene

            if gene_other.match(/Fail/i)
              failed_gene = genes['gene (other)']
              process_status_genes(genotype, 9, failed_gene, genotypes)
              remaining_genes -= failed_gene
            end

            process_status_genes(genotype, 1, remaining_genes, genotypes)
          end

          def process_other_gene(genes, genotype, genotypes, record)
            pos_gene = @gene_other_brca_size == 1 ? genes['gene (other)'] : genes['variant dna']
            if pos_gene.present?
              process_status_genes(genotype, 2, pos_gene, genotypes)
              remaining_genes = @all_genes - pos_gene
              process_status_genes(genotype, 1, remaining_genes, genotypes)
            else
              assign_status_on_gene_other(record, genes, genotype, genotypes)
            end
          end

          def assign_status_on_gene_other(record, genes, genotype, genotypes)
            binding.pry if record.raw_fields['servicereportidentifier'] == 'V001777'
            gene_other = record.raw_fields['gene (other)']
            remaining_genes = @all_genes
            case gene_other
            when /Fail/i
              process_failed_gene_other(genes, genotype, genotypes, remaining_genes)
            when /\?\z/i
              process_status_genes(genotype, 4, genes['gene'], genotypes)
            when /^c\.|^Ex.*Del\z|^Ex.*Dup\z|^Het\sDel|^Het\sDup/ix
              process_pathogenic_gene_other(genotype, genes, remaining_genes, genotypes)
            when /^#{BRCA_GENE_REGEX}\sClass\sV,\s#{BRCA_GENE_REGEX}\sN\z/i
              process_class_v_gene_other(gene_other, genotype, genotypes)
            else
              process_status_genes(genotype, 4, @all_genes, genotypes)
            end
          end

          def process_failed_gene_other(genes, genotype, genotypes, remaining_genes)
            if genes['gene (other)'].present?
              process_status_genes(genotype, 9, genes['gene (other)'], genotypes)
              remaining_genes -= genes['gene (other)']
            elsif genes['gene']
              process_status_genes(genotype, 10, genes['gene'], genotypes)
              remaining_genes -= genes['gene']
            end
            process_status_genes(genotype, 1, remaining_genes, genotypes)
          end

          def process_pathogenic_gene_other(genotype, genes, remaining_genes, genotypes)
            process_status_genes(genotype, 2, genes['gene'], genotypes)

            remaining_genes -= genes['gene']
            process_status_genes(genotype, 1, remaining_genes, genotypes)
          end

          # "gene1 Class V, gene2 N"
          def process_class_v_gene_other(gene_other, genotype, genotypes)
            class_5_gene = gene_other.split(',').first.scan(BRCA_GENE_REGEX)
            process_status_genes(genotype, 2, class_5_gene, genotypes)
            normal_gene = gene_other.split(',').last.scan(BRCA_GENE_REGEX)
            process_status_genes(genotype, 1, normal_gene, genotypes)
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

            record_gene = genotype.attribute_map['gene']

            ['variant dna', 'gene (other)'].each do |column|
              next unless EXON_REGEX.match(record.raw_fields[column])

              gene_list = record.raw_fields[column]&.scan(BRCA_GENE_REGEX)
              gene_list.each do |gene|
                next if gene_list.blank?

                gene = BRCA_GENE_MAP[gene][0]
                gene_integer = BRCA_INTEGER_MAP[gene]
                genotype.add_status(1) if gene_integer != record_gene
              end
              next unless genotype.attribute_map['teststatus'] == 2

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
