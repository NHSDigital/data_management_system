require 'possibly'
require 'pry'
require 'Date'

module Import
  module Brca
    module Providers
      module StGeorge
        class StGeorgeHandler < Import::Germline::ProviderHandler
          include Import::Helpers::Brca::Providers::Rj7::Constants

          def process_fields(record)
            return unless new_format_file?
            genotype = Import::Brca::Core::GenotypeBrca.new(record)
            genotype.add_passthrough_fields(record.mapped_fields,
                                            record.raw_fields,
                                            PASS_THROUGH_FIELDS)
            assign_test_type(genotype,record)
            assign_test_scope(genotype, record)

            res = process_variants_from_record(genotype, record)
            res.each { |cur_genotype| @persister.integrate_and_store(cur_genotype) }
          end


          def new_format_file?
              #TODO: FIlename needs to contain HBOC
          end

          def assign_test_type(genotype, record)
            return if record.raw_fields['moleculartestingtype'].nil?

            testtype = TEST_TYPE_MAP[record.raw_fields['moleculartestingtype']]
            if testtype == 'predictive'
              genotype.add_molecular_testing_type('predictive')
            elsif testtype == 'diagnostic'
              genotype.add_molecular_testing_type('diagnostic')
            end
          end


          def process_genes_targeted(genotype, record, genes)
            genotypes=[]
            genes.append(BRCA_GENE_MAP[record.raw_fields['gene']])
            genes.append(BRCA_GENE_MAP[record.raw_fields['gene(other)']])
            genes.each do |gene|
              genotype_dup = genotype.dup
              genotype_dup.add_gene(gene)
              genotypes.append(genotype_dup)
            end
            genotypes
          end


          def process_genes_full_screen(genotype, record)
            #TODO handle BRCA1 so record isn't made twice
            genotypes=[]
            genes_dict={}
            columns=['gene', 'gene(other)', 'variant dna']
            columns.each do |column|
              genes=[]
              gene_list= BRCA_GENE_REGEX.match(record.mapped_fields['gene'])
              if column == 'test/panel'
                genes_list.append(process_R208(genotype, record, genes))
              end
              gene_list.each do |gene|
                 gene=BRCA_GENE_MAP[gene]
                 genes.append(gene)
              end
              genes_dict[column]=genes
            end
            handle_test_status_full_screen(record, genotype, genes_dict)

          end


          def handle_test_status_full_screen(record, genotype, genes)
            genotypes[]
            columns=['gene', 'gene(other)','variant dna', 'test/panel' ]
            columns.each do |column|
              genes[column].each do|gene|
                genotype_dup = genotype.dup
                genotype_dup.add_gene(gene)
                assign_test_status_full_screen(record, gene, genes, genotype_dup, column)
                genotypes.append(genotype_dup)
              end
            end
          end 

          def assign_test_scope(genotype, record)
            testscope = TEST_SCOPE_MAP[record.raw_fields['moleculartestingtype']]
            if testscope == 'targeted'
              genotype.add_test_scope(:targeted_mutation)
              assign_test_status_targeted(genotype, record)
              process_genes_targeted(genotype, record, [])
              assign_test_status_targeted(genotype,record)
            elsif testscope == 'fullscreen'
              genotype.add_test_scope(:full_screen)
             # process_genes_full_screen(genotype, record)
            else
              genotype.add_test_scope(:no_genetictestscope)
            end
          end

          def assign_test_status_full_screen(record, gene, genes, genotype, column)
            # interrogate variant dna column
            if record.raw_fields['variant dna']!=nil
              if record.raw_fields['variant dna'].match(/Fail/ix)
                genotype.add_status(9)
              elsif record.raw_fields['variant dna']=='N'
                genotype.add_status(1)
              elsif record.raw_fields['gene']!=nil && record.raw_fields['gene(other)'].nil?
                if column=='gene'
                  genotype.add_status(2)
                else  
                  genotype.add_status(1)
                end
              elsif record.raw_fields['gene']!=nil && record.raw_fields['gene(other)']!=nil
                if column=='gene'
                  genotype.add_status(2)
                elsif column =='gene(other)'
                  gene_values= record.raw_fields['gene(other)'].scan(BRCA_GENE_REGEX)
                  gene_values.each do |gene_value|
                    mapped_gene_values=[]
                    mapped_gene_values.append(BRCA_GENE_MAP[gene_value])
                    mapped_gene_values[0]&.each do |value|
                      if  (value==gene)
                      #need to deal with BRCA1+2 => its not working at this part
                        if /#{gene_value}\s?\(?fail\)?/i.match(record.raw_fields['gene(other)'])
                          genotype.add_status(9)
                        else
                          genotype.add_status(1)
                        end
                      end
                    end
                  end
                end
              elsif record.raw_fields['gene']==nil && ((genes[:'gene(other)']).nil? ||(genes[:'gene(other)']).length > 1)
                if column=='variant dna'
                  genotype.add_status(2)
                else 
                  genotype.add_status(1)
                end
              elsif record.raw_fields['gene']==nil && (genes[:'gene(other)']).length == 1 
                if column=='gene(other)'
                  genotype.add_status(2)
                else 
                  genotype.add_status(1)
                end
              end
            #interrogate raw gene(other)
            elsif (/fail/i.match(record.raw_fields['gene(other)']) ).present?
              gene_list= record.raw_fields['gene(other)'].scan(BRCA_GENE_REGEX)
              if gene_list.length>=1
                gene_list.each do |gene_value|
                  mapped_gene_values=[]
                  mapped_gene_values.append(BRCA_GENE_MAP[gene_value])
                  mapped_gene_values[0]&.each do |value|
                    if  (value==gene)
                      if /#{gene_value}\s?\(?fail\)?/i.match(record.raw_fields['gene(other)'])
                        genotype.add_status(9)
                      else
                        genotype.add_status(1)
                      end
                    end
                  end
                end
              else
                if column=='gene'
                    genotype.add_status(10)
                else 
                    genotype.add_status(1)
                end
              end
            elsif record.raw_fields['gene(other)'].match(/c\.|Ex*Del|Ex*Dup|Het\sDel*|Het\sDup*/ix)
              if column=='gene(other)'
                genotype.add_status(2)
              else
                genotype.add_status(1)  
              end
            #TODO could this include brca1/2
            else 
              genotype.add_status(4)
              gene_list= record.raw_fields['gene(other)'].scan(BRCA_GENE_REGEX)
              if gene_list.length >1
                gene_list.each do |gene1|
                  gene_list.each do |gene2|
                    if /#{gene1}\sClass\sV,\s#{gene2}\sN/i.match(record.raw_fields['gene(other)'])
                      gene1=BRCA_GENE_MAP[gene1]
                      gene2=BRCA_GENE_MAP[gene2]
                      if gene==gene1[0]
                        genotype.add_status(2)
                      elsif gene==gene2[0]
                        genotype.add_status(1)
                      end
                    end
                  end
                end
              end
            end
          end

          def process_R208(genotype, record, genes)
            if record.raw_fields['test/panel']=='R208'
              date=DateTime.parse(record.raw_fields['authoriseddate'])
              if date<DateTime.parse('01/08/2022')
                print("first_panel")
                r208_panel_genes=['BRCA1', 'BRCA2']
              elsif DateTime.parse('31/07/2022')<date && date<DateTime.parse('16/11/2022')
                print("second panel")
                r208_panel_genes=['BRCA1', 'BRCA2', 'CHEK2', 'PALB2', 'ATM']
              elsif date>DateTime.parse('15/07/2022')
                  print("third_panel")
                  r208_panel_genes=['BRCA1', 'BRCA2', 'CHEK2', 'PALB2', 'ATM', 'RAD51C', 'RAD51D']
              end
            r208_panel_genes
            end
          end




          def assign_test_status_targeted(genotype, record)
            if record.raw_fields['gene(other)'].match(/Fail/ix)
              genotype.add_status(9)
            elsif record.raw_fields['gene(other)'].match(/het|del|dup|c\./ix)
              genotype.add_status(2)
            elsif record.raw_fields['variant dna'].match(/Fail|Wrong\samplicon\stested/ix)
              genotype.add_status(9)
            elsif record.raw_fields['variant dna']=='N'
              genotype.add_status(1)
            elsif record.raw_fields['variant dna'].match(/het|del|dup|c\./ix)
              genotype.add_status(2)
            elsif record.raw_fields['variant protein']=='N'
              genotype.add_status(1)
            elsif record.raw_fields['variant protein'].blank?
              genotype.add_status(4)
            else
              #TODO ask for rule here  
            end

          end


          def process_variants(genotype, record)
          
          end
        end
        end
        # rubocop:enable Metrics/ClassLength
      end
    end
  end

