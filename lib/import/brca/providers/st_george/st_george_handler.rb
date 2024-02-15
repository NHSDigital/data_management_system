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

          def assign_test_scope(genotype, record)
            testscope = TEST_SCOPE_MAP[record.raw_fields['moleculartestingtype']]
            if testscope == 'targeted'
              genotype.add_test_scope(:targeted_mutation)
              process_genes(genotype, record)
              assign_test_status_targeted(genotype,record)
            elsif testscope == 'fullscreen'
              genotype.add_test_scope(:full_screen)
              process_genes_full_screen(genotype, record)
            else
              genotype.add_test_scope(:no_genetictestscope)
            end
          end



          def process_genes(genotype, record)
            genes=[]
            genes.append(BRCA_GENE_MAP[record.raw_fields['gene']])
            genes.append(BRCA_GENE_MAP[record.raw_fields['gene(other)']])
            genes.each do |gene|
              #TODO handle if more than one gene listed in gene field
            end
          end


          def process_genes_full_screen(genotype, record)
            genes=[]
            panel_genes=[]
            genes= process_genes(genotype, record)
            genes.append(BRCA_GENE_MAP[record.raw_fields['variant dna']])
            genes.append(BRCA_GENE_MAP[record.raw_fields['test/panel']])
            genes=process_R208(genotype, record, genes)
            genes
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
            genes.append(r208_panel_genes)
            genes
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

          def assign_test_status_full_screen
          end

          def process_variants(genotype, record)
          
          end
        end
        # rubocop:enable Metrics/ClassLength
      end
    end
  end
end
