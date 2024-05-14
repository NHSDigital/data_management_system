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
      

            assign_test_type(genotype, record)
            genotype = assign_test_scope(genotype, record)

            genotypes = fill_genotypes(genotype, record)

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
            
            # elsif genotype.attribute_map['genetictestscope'] == "Full screen Colorectal Lynch or MMR"  #need to add in full screen methods here
            #   genes = process_genes_targeted(record)

            #   genotypes = duplicate_genotype_targeted(genes, genotype)
            #   genotypes.each do |single_genotype|
            #     assign_test_status_targeted(single_genotype, record)
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

          gene_list.each do |gene|
            gene = CRC_GENE_MAP[gene]
            genes.append(gene)
          end
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
            genotype = genotype.dup if genes.flatten.uniq.size >1
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

        genotype.add_status(status)

      end 

      def assign_test_status_targeted_support(record, test_values, _genotype)
        #Loop through the dictionaries in regex and assing the correct associated statusß
        column = test_values[:column]
        status = test_values[:status]
        expression = test_values[:expression]
        match = test_values[:regex]

        unknown_status_regex= '/SNP\spresent|see\scomments/ix'

        if match == 'regex'
          status if record.raw_fields[column].present? && record.raw_fields[column].scan(expression).size.positive?
        elsif record.raw_fields[column].present? && record.raw_fields[column] == expression
          status
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
end 

