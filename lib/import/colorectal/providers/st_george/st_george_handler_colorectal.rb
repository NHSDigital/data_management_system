require 'possibly'
require 'pry'
require 'Date'

module Import
  module Colorectal
    module Providers
      module StGeorge
        # Process St George-specific record details into generalized internal genotype format
        class StGeorgeHandlerColorectal < Import::Germline::ProviderHandler
          include Import::Helpers::Colorectal::Providers::Rj7::Constants

          def process_fields(record)
            genotype = Import::Colorectal::Core::Genocolorectal.new(record)

            
            # records using new importer should only have SRIs starting with V
            return unless record.raw_fields['servicereportidentifier'].start_with?('V')

            genotype.add_passthrough_fields(record.mapped_fields, record.raw_fields, PASS_THROUGH_FIELDS)
            puts "### SRI ###### "
            puts record.raw_fields['servicereportidentifier']
            
      

            assign_test_type(genotype, record)
            genotype = assign_test_scope(genotype, record)

            puts "### GENOTYPE GENETIC TEST SCOPE ###"
            puts genotype.attribute_map['genetictestscope']

            puts "### GENOTYPE GENETIC TEST TYPE ###"
            puts genotype.attribute_map['moleculartestingtype']

            genotypes = fill_genotypes(genotype, record)

            puts "### GENOTYPES ###"
            puts genotypes

            genotypes.each do |single_genotype|
              process_variants(single_genotype, record)
              @persister.integrate_and_store(single_genotype)
            end


          end 

          def assign_test_type(genotype, record)
            # extract molecular testing type from the raw record
            # map molecular testing type and assign to genotype using
            # add_molecular_testing_type method from genocolorectal.rb

            return if record.raw_fields['moleculartestingtype'].blank?

            return unless TEST_TYPE_MAP[record.raw_fields['moleculartestingtype']]

            genotype.add_molecular_testing_type_strict(TEST_TYPE_MAP[record.raw_fields['moleculartestingtype']])

          end

          def assign_test_scope(genotype, record)
            # extract molecular testing type from the raw record
            # map molecular testing type and assign to genotype using
            # add_test_scope method from genocolorectal.rb
        
            testscope = TEST_SCOPE_MAP[record.raw_fields['moleculartestingtype']]
            if testscope == 'targeted'
              genotype.add_test_scope(:targeted_mutation)
            elsif testscope == 'fullscreen'
              genotype.add_test_scope(:full_screen)
            else
              genotype.add_test_scope(:no_genetictestscope)
            end
            genotype
          end


          def fill_genotypes(genotype, record)
            # Check if record is full screen or targeted and handle accordingly
            # process the genes, genotypes and test status for each gene listed in the genotype

            genotypes =[]

            #check if it is targeted 
            if genotype.attribute_map['genetictestscope'] == "Targeted Colorectal Lynch or MMR"
              genes = process_genes_targeted(record)

              genotypes = duplicate_genotype_targeted(genes, genotype)
              genotypes.each do |single_genotype|
                assign_test_status_targeted(single_genotype, record)
              end
            

            elsif genotype.attribute_map['genetictestscope'] == 'Full screen Colorectal Lynch or MMR'
              genes_dict = process_genes_fullscreen(genotype, record)
              genotypes = handle_test_status_fullscreen(record, genotype, genes_dict)

            end 
            genotypes
          end 


         def process_genes_targeted(record)
          #Targeted tests only
          #Creates a list of genes included in the record that match the BRCA gene regez
          #Genotype is suplicated fro every gene in the list 
          #list of genotypes is returned

          columns = ['gene', 'gene (other)']
          genes =[]
          columns.each do |column|
            gene_list = record.raw_fields[column]&.scan(CRC_GENE_REGEX)
            next if gene_list.blank?
          end 

          gene_list.each do |gene|
            gene = CRC_GENE_MAP[gene]
            genes.append(gene)
          end
        
         genes
        end



        def duplicate_genotype_targeted(genes, genotype)
          #When there is more the one gene listed, a seperate genotype is created for each
          #each genotype is then adde to teh genotypes list which is then returned
          genotypes = []

          genes.each do |gene|
            next if gene.blank?

            gene.each do |gene_value|
              #only duplicate if there is more than one gene in the list
              genotype = genotype.dup_colo if genes.flatten.uniq.size >1
              genotype.add_gene_colorectal(gene_value)
              genotypes.append(genotype)
            end 
          end 
          genotypes
        end

        def assign_test_status_targeted(genotype, record)
          #Loop through the list of dictionarys in TARGTEED_TEST_STATUS within constants.rb
          #run support method for each dictionary item with the values

          status = nil
          TARGETED_TEST_STATUS.each do |test_values|
            status = assign_test_status_targeted_support(record, test_values, genotype)

            break unless status.nil?
          end 

          status = 4 if status.nil? && record.raw_fields['variant protein'].blank?

          update_status(2, 1, column, 'gene', genotype) if status.nil? && record.raw_fields['variant protein'].match(/p\./ix)

          genotype.add_status(status)

        end 

        def assign_test_status_targeted_support(record, test_values, _genotype)
          #Loop through the dictionaries in regex and assing the correct associated statusß
          column = test_values[:column]
          status = test_values[:status]
          expression = test_values[:expression]
          match = test_values[:regex]

          #unknown_status_regex= '/SNP\spresent|see\scomments/ix'

          if match == 'regex'
            status if record.raw_fields[column].present? && record.raw_fields[column].scan(expression).size.positive?
          elsif record.raw_fields[column].present? && record.raw_fields[column] == expression
            status
          end 

        end 

        def process_genes_fullscreen(_genotype, record)
          genes_dict={}

          ['gene', 'gene (other)', 'variant dna', 'test/panel'].each do |column|
    
            genes = []
            gene_list = record.raw_fields[column]&.scan(CRC_GENE_REGEX)

            
          

            gene_list = process_test_panels(record, gene_list, column) if column == 'test/panel'


            next if gene_list.nil?

            gene_list.each do |gene|
              CRC_GENE_MAP[gene]&.each do |gene_value|
                genes.append(gene_value)
                
              end
              
            end
            puts "### Gene List ###"
            puts gene_list

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
          
          r211 = record.raw_fields[column]&.eql?('R211')

          date = DateTime.parse(record.raw_fields['authoriseddate'])
          if r211.present? && date < DateTime.parse('18/07/2022')
            panel_genes_list=FULL_SCREEN_TESTS_MAP['R211']

          elsif r211.present? && date > DateTime.parse('18/07/2022')
            panel_genes_list=FULL_SCREEN_TESTS_MAP['R211_']

          end       
          gene_list
          binding.pry
        end

        def handle_test_status_fullscreen(record, genotype, genes)
          genotypes=[]
          columns = ['gene', 'gene (other)', 'variant_dna', 'test/panel']
          counter = 0
          columns.each do |column|
            genes[column]&.each do |gene|
              #duplicate genotype only if there is more than one gene present
              genotype=genotype.dup_colo if counter.positive?
              genotype.add_gene_colorectal(gene)
              genotype.add_status(4)
              assign_test_status_fullscreen(record, gene, genes, genotype, column)
              genotypes.append(genotype)
              counter +=1
            end
          end
          genotypes
        end

        def assign_test_status_fullscreen (record, genotype, genes, column, gene)
          #interrogate the variant dna column and raw gene (other) column
          if record.raw_fields['variant dna'].present?
            interrogate_variant_dna_column(record, genotype, genes, column, gene)
          elsif record.raw_fields['variant protein'].present?
            interrogate_variant_protein_column(record, genotype, genes, column, gene)
          end

        end 



        def interrogate_variant_dna_column(record, genotype, genes, column, gene)

          variant_regex=/het\sdel|het\sdup|het\sinv|^ex.*del|^ex.*dup|^ex.*inv|^del\sex|^dup\sex|^inv\sex|^c\.|inversion/ix
        

          if record.raw_fields['variant dna'].match(/Fail/ix)         
            genotype.add_status(9)
          elsif record.raw_fields['variant dna'] == 'N'
            puts record.raw_fields['variant dna']
            genotype.add_status(1)
          elsif record.raw_fields['variant dna'].match(variant_regex) && !record.raw_fields['gene'].blank?
            update_status(2, 1, column, 'gene', genotype)
          elsif record.raw_fields['variant dna'].match(variant_regex) && record.raw_fields['gene'].blank? && record.raw_fields['gene (other)'].length == 1
            update_status(2, 1, column, 'gene', genotype)
          elsif record.raw_fields['variant dna'].match(variant_regex) && record.raw_fields['gene'].blank? && record.raw_fields['gene (other)'].length > 1 && !genes['variant dna'].nil? #can gene (other) be null in this scenario as wel?????
            #Gene should be specified in raw:variant dna; assign 2 (abnormal) for the specified gene and 1 (normal) for all other genes.
            update_status(2, 1, column, 'variant dna', genotype)
          else
            interrogate_variant_protein_column(record, genotype, genes, column, gene)
          end

          puts genotype.attribute_map['teststatus']
        end 

        def interrogate_variant_protein_column(record, genotype, genes, column, gene)
          if record.raw_fields['variant protein'].match(/fail/ix)
            genotype.add_status(9)
          elsif record.raw_fields['variant protein'].match(/p.*/ix)
            update_status(2, 1, column, 'gene', genotype)
          else
            genotype.add_status(1)
          end 


        end 





        def update_status(status1, status2, column, column_name, genotype)
          # update genotype status depending on if the gene is in the same column that the rule applies to

          if column == column_name
            genotype.add_status(status1)
          else
            genotype.add_status(status2)
          end
        end







        def process_variants(genotype, record)
          # add hgvsc and hgvsp codes - if not present then run process_location_type_zygosity
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
            process_location_type_zygosity(genotype, record)
          end
        end

        def process_location_type_zygosity(genotype, record)
          # use methods in genotype.rb to add exon location, variant type and zygosity
          ['variant dna', 'gene (other)'].each do |column|
            next unless EXON_REGEX.match(record.raw_fields[column])

            genotype.add_exon_location($LAST_MATCH_INFO[:exons])
            genotype.add_variant_type($LAST_MATCH_INFO[:mutationtype])
            genotype.add_zygosity($LAST_MATCH_INFO[:zygosity])
          end
            





























        end
      end
    end
  end
end

