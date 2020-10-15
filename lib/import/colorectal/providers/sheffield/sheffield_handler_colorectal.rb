require 'import/central_logger'
require 'import/brca/core/extraction_utilities'
require 'import/brca/core/provider_handler'
require 'pry'
require 'possibly'

module Import
  module Colorectal
    module Providers
      module Sheffield
        # Process Sheffield-specific record details into generalized internal genotype format
        class SheffieldHandlerColorectal < Import::Brca::Core::ProviderHandler
          # TEST_SCOPE_MAPPING = { 'BRCA1 and 2 familial mutation' => :targeted_mutation,
          #                        'Breast & Ovarian cancer panel' => :full_screen,
          #                        'Breast Ovarian & Colorectal cancer panel' => :full_screen,
          #                        'Confirmation of Familial Mutation' => :targeted_mutation,
          #                        'Diagnostic testing for known mutation' => :targeted_mutation,
          #                        'Confirmation of Research Result' => :targeted_mutation,
          #                        'Predictive testing' => :targeted_mutation,
          #                        'Family Studies' => :targeted_mutation} .freeze

          TEST_TYPE_MAPPING_COLO = { 'Diagnostic testing' => :diagnostic,
                                     'Further sample for diagnostic testing' => :diagnostic,
                                     'Confirmation of Familial Mutation' => :diagnostic,
                                     'Confirmation of Research Result' => :diagnostic,
                                     'Diagnostic testing for known mutation' => :diagnostic,
                                     'Predictive testing' => :predictive,
                                     'Family Studies' => :predictive } .freeze

          PASS_THROUGH_FIELDS_COLO = %w[consultantcode
                                        providercode
                                        collecteddate
                                        receiveddate
                                        authoriseddate
                                        servicereportidentifier
                                        genotype
                                        age].freeze

          CDNA_REGEX = /c\.(?<cdna>[0-9]+[a-z]+>[a-z]+)|c\.(.)?(?<cdna>[0-9a-z]+>[a-z])|
          c\.(.)?(?<cdna>[0-9]+(\+|\-)?[0-9a-z]+>[a-z])|c\.(.)?(?<cdna>[0-9]+[a-z]+)|
          c\.(.)?(?<cdna>[0-9]+_[0-9]+[a-z]+)|c\.(.)?(?<cdna>[0-9]+.[0-9][a-z]>[a-z])/ix.freeze

          PROTEIN_REGEX = /p\.(\[)?\((?<impact>[a-z]+[0-9]+([a-z]+|\*))\)(\])?/i.freeze
          BOCC = %w[EPCAM MLH1 MSH2 MSH6 PTEN STK11 PMS2].freeze
          CCP_APCMUTYH = %w[APC MUTYH].freeze
          CCP_CRC_FULLPANEL = %w[MLH1 MSH2 MSH6 PMS2 EPCAM APC MUTYH
                                 BMPR1A PTEN POLD1 POLE SMAD4 STK11].freeze

          # Il resto di CCP lo prendo direttamente da karyotyping_method
          R209_NGS = %w[APC MUTYH].freeze
          R209_UNK_SMALL = %w[MLH1 MSH2 MSH6 PMS2 EPCAM APC MUTYH BMPR1A
                              PTEN POLD1 POLE SMAD4 STK11].freeze
          R209_UNK_MLPA = %w[MLH1 MSH2 APC MUTYH].freeze
          R210_FULLSCREEN = %w[MLH1 MSH2 MSH6 PMS2 EPCAM].freeze
          R211_FULLSCREEN = %w[APC MUTYH].freeze
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
                                                STK11)/xi .freeze # Added by
          NULL_TARGETED_TEST_REGEX = /(?<colorectal>APC|BMPR1A|EPCAM|
                                    MLH1|MSH2|MSH6|MUTYH|PMS2|POLD1|
                                    POLE|PTEN|SMAD4|STK11):
                                    \sFamilial\spathogenic\smutation\snot\sdetected/ix .freeze

          def initialize(batch)
            @failed_genotype_counter = 0
            @successful_gene_counter = 0
            @gene_counter = 0
            @failed_gene_counter = 0
            @negative_test = 0
            @positive_test = 0
            super
          end

          def process_fields(record)
            genocolorectal = Import::Colorectal::Core::Genocolorectal.new(record)
            genocolorectal.add_passthrough_fields(record.mapped_fields,
                                                  record.raw_fields,
                                                  PASS_THROUGH_FIELDS_COLO)
            add_test_scope_from_karyo(genocolorectal, record)
            res = add_colorectal_from_raw_test(genocolorectal, record)
            res.map { |cur_genotype| @persister.integrate_and_store(cur_genotype) }
          end

          def add_test_scope_from_karyo(genocolorectal, record)
            geno = record.mapped_fields['genetictestscope']
            karyo = record.raw_fields['karyotypingmethod']
            if geno == 'Colorectal cancer panel'
              if karyo == 'PTEN familial mutation' || karyo == 'STK11 familial mutation'
                genocolorectal.add_test_scope(:targeted_mutation)
                @logger.debug "ADDED TARGETED TEST for: #{record.raw_fields['karyotypingmethod']}"
              else
                genocolorectal.add_test_scope(:full_screen)
                @logger.debug "ADDED FULL_SCREEN TEST for: #{record.raw_fields['karyotypingmethod']}"
              end
            elsif geno == 'R210 :: Inherited MMR deficiency (Lynch syndrome)'
              if karyo == 'R242.1 :: Predictive testing' || karyo == 'R242.1 :: Predictive MLPA'
                genocolorectal.add_test_scope(:targeted_mutation)
                @logger.debug "ADDED TARGETED TEST for: #{record.raw_fields['karyotypingmethod']}"
              else
                genocolorectal.add_test_scope(:full_screen)
                @logger.debug "ADDED FULL_SCREEN TEST for: #{record.raw_fields['karyotypingmethod']}"
              end
            elsif geno == 'R209 :: Inherited colorectal cancer (with or without polyposis)'
              if karyo == 'R242.1 :: Predictive testing'
                genocolorectal.add_test_scope(:targeted_mutation)
                @logger.debug "ADDED TARGETED TEST for: #{record.raw_fields['karyotypingmethod']}"
              else
                genocolorectal.add_test_scope(:full_screen)
                @logger.debug "ADDED FULL_SCREEN TEST for: #{record.raw_fields['karyotypingmethod']}"
              end
            elsif geno == 'R211 :: Inherited polyposis - germline test'
              if karyo == 'R211.1 :: APC and MUTYH genes in Leeds'
                genocolorectal.add_test_scope(:full_screen)
                @logger.debug "ADDED FULL_SCREEN for: #{record.raw_fields['karyotypingmethod']}"
              elsif karyo == 'R387.1 ::  APC and MUTYH analysis only'
                genocolorectal.add_test_scope(:full_screen)
                @logger.debug "ADDED FULL_SCREEN for: #{record.raw_fields['karyotypingmethod']}"
              else
                genocolorectal.add_test_scope(:targeted_mutation)
                @logger.debug "ADDED TARGETED TEST for: #{record.raw_fields['karyotypingmethod']}"
              end
            elsif geno == 'Breast Ovarian & Colorectal cancer panel'
              if karyo == 'Full panel'
                genocolorectal.add_test_scope(:full_screen)
                @logger.debug "ADDED FULL_SCREEN for: #{record.raw_fields['karyotypingmethod']}"
              end
            else
              @logger.debug 'UNKNOWN GENETIC TEST SCOPE'
            end
          end

          def add_test_type(genocolorectal, record)
            Maybe(record.raw_fields['moleculartestingtype']).each do |type|
              case type
              when 'Diagnostic testing'
                genocolorectal.add_molecular_testing_type_strict(:diagnostic)
              when 'Confirmation of Familial Mutation'
                genocolorectal.add_molecular_testing_type_strict(:diagnostic)
              when 'Confirmation of Research Result'
                genocolorectal.add_molecular_testing_type_strict(:diagnostic)
              when 'Further sample for diagnostic testing'
                genocolorectal.add_molecular_testing_type_strict(:diagnostic)
              when 'Diagnostic testing for known mutation'
                genocolorectal.add_molecular_testing_type_strict(:diagnostic)
              when 'Predictive testing'
                genocolorectal.add_molecular_testing_type_strict(:predictive)
              when 'Family Studies'
                genocolorectal.add_molecular_testing_type_strict(:predictive)
              end
            end
          end

          def add_colorectal_from_raw_test(genocolorectal, record)
            colo_string = record.raw_fields['genotype']
            geno = record.mapped_fields['genetictestscope']
            karyo = record.raw_fields['karyotypingmethod']
            genotypes = []
            if genocolorectal.attribute_map['genetictestscope'] == 'Targeted Colorectal mutation test'
              if NULL_TARGETED_TEST_REGEX.match(colo_string)
                genocolorectal.add_status(1)
                genocolorectal.add_gene_colorectal(COLORECTAL_GENES_REGEX.match(colo_string)[:colorectal])
                genocolorectal.add_protein_impact(nil)
                genocolorectal.add_gene_location(nil)
                genotypes.append(genocolorectal)
              elsif COLORECTAL_GENES_REGEX.match(colo_string)
                genocolorectal.add_gene_colorectal($LAST_MATCH_INFO[:colorectal])
                process_cdna_change(genocolorectal, record)
                process_protein_impact(genocolorectal, record)
                genocolorectal.add_status(2)
                genotypes.append(genocolorectal)
              elsif karyo.scan(COLORECTAL_GENES_REGEX).empty? &&
                    colo_string.scan(/pathogenic/i).empty?
                if CDNA_REGEX.match(colo_string)[:cdna] == '3142C>T'
                  process_cdna_change(genocolorectal, record)
                  process_protein_impact(genocolorectal, record)
                  genocolorectal.add_gene_colorectal('MSH6')
                  genotypes.append(genocolorectal)
                elsif CDNA_REGEX.match(colo_string)[:cdna] == '2194C>T'
                  process_cdna_change(genocolorectal, record)
                  process_protein_impact(genocolorectal, record)
                  genocolorectal.add_gene_colorectal('MSH6')
                  genotypes.append(genocolorectal)
                elsif CDNA_REGEX.match(colo_string)[:cdna] == '164del'
                  process_cdna_change(genocolorectal, record)
                  process_protein_impact(genocolorectal, record)
                  genocolorectal.add_gene_colorectal('MLH1')
                  genotypes.append(genocolorectal)
                elsif CDNA_REGEX.match(colo_string)[:cdna] == '385_386delinsGTT'
                  process_cdna_change(genocolorectal, record)
                  process_protein_impact(genocolorectal, record)
                  genocolorectal.add_gene_colorectal('MLH1')
                  genotypes.append(genocolorectal)
                elsif CDNA_REGEX.match(colo_string)[:cdna] == '3142C>T'
                  process_cdna_change(genocolorectal, record)
                  process_protein_impact(genocolorectal, record)
                  genocolorectal.add_gene_colorectal('MSH6')
                  genotypes.append(genocolorectal)
                elsif CDNA_REGEX.match(colo_string)[:cdna] == '1958+3A>G'
                  process_cdna_change(genocolorectal, record)
                  process_protein_impact(genocolorectal, record)
                  genocolorectal.add_gene_colorectal('APC')
                  genotypes.append(genocolorectal)
                elsif CDNA_REGEX.match(colo_string)[:cdna] == '2194C>T'
                  process_cdna_change(genocolorectal, record)
                  process_protein_impact(genocolorectal, record)
                  genocolorectal.add_gene_colorectal('MSH6')
                  genotypes.append(genocolorectal)
                elsif CDNA_REGEX.match(colo_string)[:cdna] == '1732del'
                  process_cdna_change(genocolorectal, record)
                  process_protein_impact(genocolorectal, record)
                  genocolorectal.add_gene_colorectal('MSH6')
                  genotypes.append(genocolorectal)
                elsif CDNA_REGEX.match(colo_string)[:cdna] == '2194C>T'
                  process_cdna_change(genocolorectal, record)
                  process_protein_impact(genocolorectal, record)
                  genocolorectal.add_gene_colorectal('MSH6')
                  genotypes.append(genocolorectal)
                elsif CDNA_REGEX.match(colo_string)[:cdna] == '3307_3308insCA'
                  process_cdna_change(genocolorectal, record)
                  process_protein_impact(genocolorectal, record)
                  genocolorectal.add_gene_colorectal('MSH6')
                  genotypes.append(genocolorectal)
                elsif /536A>G/i.match(colo_string)
                  process_cdna_change(genocolorectal, record)
                  process_protein_impact(genocolorectal, record)
                  genocolorectal.add_gene_colorectal('MUTYH')
                  genotypes.append(genocolorectal)
                end
                genotypes
              elsif /Familial pathogenic mutation not detected/i.match(colo_string) &&
                    COLORECTAL_GENES_REGEX.match(karyo)
                genocolorectal.add_status(1)
                genocolorectal.add_gene_colorectal(COLORECTAL_GENES_REGEX.match(karyo)[:colorectal])
                genocolorectal.add_protein_impact(nil)
                genocolorectal.add_gene_location(nil)
                genotypes.append(genocolorectal)
              else
                genocolorectal.add_status(1)
                genocolorectal.add_gene_colorectal(nil)
                genocolorectal.add_protein_impact(nil)
                genocolorectal.add_gene_location(nil)
                genotypes.append(genocolorectal)
              end
            elsif genocolorectal.attribute_map['genetictestscope'] == 'Full screen Colorectal Lynch or MMR'
              if colo_string == 'Incomplete analysis - see below'
                neg_genes = karyo.scan(COLORECTAL_GENES_REGEX).compact.flatten
                neg_genes.each do |genes|
                  genocolorectal1 = genocolorectal.dup_colo
                  @logger.debug "SUCCESSFUL gene parse for negative test for: #{genes}"
                  genocolorectal1.add_status(4)
                  genocolorectal1.add_gene_colorectal(genes)
                  genocolorectal1.add_protein_impact(nil)
                  genocolorectal1.add_gene_location(nil)
                  genotypes.append(genocolorectal1)
                end
              elsif colo_string.scan(COLORECTAL_GENES_REGEX).size > 1
                if geno == 'Colorectal cancer panel'
                  if karyo == 'Full panel' ||
                     karyo == 'Extended CRC panel - analysis only' ||
                     karyo == 'Extended CRC panel' ||
                     karyo == 'Default'
                    neg_genes = CCP_CRC_FULLPANEL - colo_string.scan(COLORECTAL_GENES_REGEX).flatten
                    neg_genes.each do |genes|
                      genocolorectal1 = genocolorectal.dup_colo
                      @logger.debug "SUCCESSFUL gene parse for negative test for: #{genes}"
                      genocolorectal1.add_status(1)
                      genocolorectal1.add_gene_colorectal(genes)
                      genocolorectal1.add_protein_impact(nil)
                      genocolorectal1.add_gene_location(nil)
                      genotypes.append(genocolorectal1)
                    end
                    colo_string.scan(COLORECTAL_GENES_REGEX).zip(colo_string.scan(CDNA_REGEX).compact).each do
                      |gene, variant|
                      genocolorectal2 = genocolorectal.dup_colo
                      genocolorectal2.add_gene_colorectal(gene.join)
                      genocolorectal2.add_gene_location(variant.join.compact)
                      genotypes.append(genocolorectal2)
                    end
                  end
                elsif geno == 'R210 :: Inherited MMR deficiency (Lynch syndrome)'
                  neg_genes = R210_FULLSCREEN - colo_string.scan(COLORECTAL_GENES_REGEX).flatten
                  neg_genes.each do |genes|
                    genocolorectal1 = genocolorectal.dup_colo
                    @logger.debug "SUCCESSFUL gene parse for negative test for: #{genes}"
                    genocolorectal1.add_status(1)
                    genocolorectal1.add_gene_colorectal(genes)
                    genocolorectal1.add_protein_impact(nil)
                    genocolorectal1.add_gene_location(nil)
                    genotypes.append(genocolorectal1)
                  end
                  colo_string.scan(COLORECTAL_GENES_REGEX).zip(colo_string.scan(CDNA_REGEX).compact).each do
                    |gene, variant|
                    genocolorectal2 = genocolorectal.dup_colo
                    genocolorectal2.add_gene_colorectal(gene.join)
                    genocolorectal2.add_gene_location(variant.join.compact)
                    genotypes.append(genocolorectal2)
                  end
                end
              elsif colo_string.scan(COLORECTAL_GENES_REGEX).size == 1 ||
                    /pathogenic/i.match(colo_string) ||
                    /pathogneic/i.match(colo_string)
                if geno == 'Breast Ovarian & Colorectal cancer panel'
                  if COLORECTAL_GENES_REGEX.match(colo_string)
                    neg_genes = BOCC - [COLORECTAL_GENES_REGEX.match(colo_string)[0]]
                    neg_genes.each do |genes|
                      genocolorectal1 = genocolorectal.dup_colo
                      @logger.debug "SUCCESSFUL gene parse for negative test for: #{genes}"
                      genocolorectal1.add_status(1)
                      genocolorectal1.add_gene_colorectal(genes)
                      genocolorectal1.add_protein_impact(nil)
                      genocolorectal1.add_gene_location(nil)
                      genotypes.append(genocolorectal1)
                    end
                    genocolorectal.add_gene_colorectal($LAST_MATCH_INFO[:colorectal])
                    process_cdna_change(genocolorectal, record)
                    process_protein_impact(genocolorectal, record)
                    genocolorectal.add_status(2)
                    genotypes.append(genocolorectal)
                  else
                    BOCC.each do |genes|
                      genocolorectal1 = genocolorectal.dup_colo
                      @logger.debug "SUCCESSFUL gene parse for negative test for: #{genes}"
                      genocolorectal1.add_status(1)
                      genocolorectal1.add_gene_colorectal(genes)
                      genocolorectal1.add_protein_impact(nil)
                      genocolorectal1.add_gene_location(nil)
                      genotypes.append(genocolorectal1)
                    end
                  end
                elsif geno == 'R210 :: Inherited MMR deficiency (Lynch syndrome)'
                  if COLORECTAL_GENES_REGEX.match(colo_string)
                    neg_genes = R210_FULLSCREEN - [COLORECTAL_GENES_REGEX.match(colo_string)[0]]
                    neg_genes.each do |genes|
                      genocolorectal1 = genocolorectal.dup_colo
                      @logger.debug "SUCCESSFUL gene parse for negative test for: #{genes}"
                      genocolorectal1.add_status(1)
                      genocolorectal1.add_gene_colorectal(genes)
                      genocolorectal1.add_protein_impact(nil)
                      genocolorectal1.add_gene_location(nil)
                      genotypes.append(genocolorectal1)
                    end
                    genocolorectal.add_gene_colorectal($LAST_MATCH_INFO[:colorectal])
                    process_cdna_change(genocolorectal, record)
                    process_protein_impact(genocolorectal, record)
                    genocolorectal.add_status(2)
                    genotypes.append(genocolorectal)
                  else
                    R210_FULLSCREEN.each do |genes|
                      genocolorectal1 = genocolorectal.dup_colo
                      @logger.debug "SUCCESSFUL gene parse for negative test for: #{genes}"
                      genocolorectal1.add_status(1)
                      genocolorectal1.add_gene_colorectal(genes)
                      genocolorectal1.add_protein_impact(nil)
                      genocolorectal1.add_gene_location(nil)
                      genotypes.append(genocolorectal1)
                    end
                  end
                elsif geno == 'R211 :: Inherited polyposis - germline test'
                  if COLORECTAL_GENES_REGEX.match(colo_string)
                    neg_genes = R211_FULLSCREEN - [COLORECTAL_GENES_REGEX.match(colo_string)[0]]
                    neg_genes.each do |genes|
                      genocolorectal1 = genocolorectal.dup_colo
                      @logger.debug "SUCCESSFUL gene parse for negative test for: #{genes}"
                      genocolorectal1.add_status(1)
                      genocolorectal1.add_gene_colorectal(genes)
                      genocolorectal1.add_protein_impact(nil)
                      genocolorectal1.add_gene_location(nil)
                      genotypes.append(genocolorectal1)
                    end
                    genocolorectal.add_gene_colorectal($LAST_MATCH_INFO[:colorectal])
                    process_cdna_change(genocolorectal, record)
                    process_protein_impact(genocolorectal, record)
                    genocolorectal.add_status(2)
                    genotypes.append(genocolorectal)
                  else
                    R211_FULLSCREEN.each do |genes|
                      genocolorectal1 = genocolorectal.dup_colo
                      @logger.debug "SUCCESSFUL gene parse for negative test for: #{genes}"
                      genocolorectal1.add_status(1)
                      genocolorectal1.add_gene_colorectal(genes)
                      genocolorectal1.add_protein_impact(nil)
                      genocolorectal1.add_gene_location(nil)
                      genotypes.append(genocolorectal1)
                    end
                  end
                elsif geno == 'R209 :: Inherited colorectal cancer (with or without polyposis)'
                  if /Small panel/i.match(karyo)
                    if COLORECTAL_GENES_REGEX.match(colo_string)
                      neg_genes = R209_UNK_SMALL - [COLORECTAL_GENES_REGEX.match(colo_string)[0]]
                      neg_genes.each do |genes|
                        genocolorectal1 = genocolorectal.dup_colo
                        @logger.debug "SUCCESSFUL gene parse for negative test for: #{genes}"
                        genocolorectal1.add_status(1)
                        genocolorectal1.add_gene_colorectal(genes)
                        genocolorectal1.add_protein_impact(nil)
                        genocolorectal1.add_gene_location(nil)
                        genotypes.append(genocolorectal1)
                      end
                      genocolorectal.add_gene_colorectal($LAST_MATCH_INFO[:colorectal])
                      process_cdna_change(genocolorectal, record)
                      process_protein_impact(genocolorectal, record)
                      genocolorectal.add_status(2)
                      genotypes.append(genocolorectal)
                    else
                      R209_UNK_SMALL.each do |genes|
                        genocolorectal1 = genocolorectal.dup_colo
                        genocolorectal1.add_status(1)
                        genocolorectal1.add_gene_colorectal(genes)
                        genocolorectal1.add_protein_impact(nil)
                        genocolorectal1.add_gene_location(nil)
                        genotypes.append(genocolorectal1)
                      end
                    end
                  elsif /R209\.2/i.match(karyo)
                    if COLORECTAL_GENES_REGEX.match(colo_string)
                      neg_genes = R209_UNK_MLPA - [COLORECTAL_GENES_REGEX.match(colo_string)[0]]
                      neg_genes.each do |genes|
                        genocolorectal1 = genocolorectal.dup_colo
                        @logger.debug "SUCCESSFUL gene parse for negative test for: #{genes}"
                        genocolorectal1.add_status(1)
                        genocolorectal1.add_gene_colorectal(genes)
                        genocolorectal1.add_protein_impact(nil)
                        genocolorectal1.add_gene_location(nil)
                        genotypes.append(genocolorectal1)
                      end
                      genocolorectal.add_gene_colorectal($LAST_MATCH_INFO[:colorectal])
                      process_cdna_change(genocolorectal, record)
                      process_protein_impact(genocolorectal, record)
                      genocolorectal.add_status(2)
                      genotypes.append(genocolorectal)
                    else
                      R209_UNK_MLPA.each do |genes|
                        genocolorectal1 = genocolorectal.dup_colo
                        genocolorectal1.add_status(1)
                        genocolorectal1.add_gene_colorectal(genes)
                        genocolorectal1.add_protein_impact(nil)
                        genocolorectal1.add_gene_location(nil)
                        genotypes.append(genocolorectal1)
                      end
                    end
                  elsif karyo.scan(COLORECTAL_GENES_REGEX).size > 1
                    if COLORECTAL_GENES_REGEX.match(colo_string)
                      karyogenes = karyo.scan(COLORECTAL_GENES_REGEX).compact.flatten
                      matchedgenes = [COLORECTAL_GENES_REGEX.match(colo_string)[0]]
                      neg_genes = karyogenes - matchedgenes
                      neg_genes.each do |genes|
                        genocolorectal1 = genocolorectal.dup_colo
                        @logger.debug "SUCCESSFUL gene parse for negative test for: #{genes}"
                        genocolorectal1.add_status(1)
                        genocolorectal1.add_gene_colorectal(genes)
                        genocolorectal1.add_protein_impact(nil)
                        genocolorectal1.add_gene_location(nil)
                        genotypes.append(genocolorectal1)
                      end
                      genocolorectal.add_gene_colorectal($LAST_MATCH_INFO[:colorectal])
                      process_cdna_change(genocolorectal, record)
                      process_protein_impact(genocolorectal, record)
                      genocolorectal.add_status(2)
                      genotypes.append(genocolorectal)
                    else
                      karyo.scan(COLORECTAL_GENES_REGEX).compact.flatten.each do |genes|
                        genocolorectal1 = genocolorectal.dup_colo
                        genocolorectal1.add_status(1)
                        genocolorectal1.add_gene_colorectal(genes)
                        genocolorectal1.add_protein_impact(nil)
                        genocolorectal1.add_gene_location(nil)
                        genotypes.append(genocolorectal1)
                      end
                    end
                  end
                elsif geno == 'Colorectal cancer panel'
                  if karyo == 'Full panel' ||
                     karyo == 'Extended CRC panel - analysis only' ||
                     karyo == 'Extended CRC panel' ||
                     karyo == 'Default'
                    if COLORECTAL_GENES_REGEX.match(colo_string)
                      neg_genes = CCP_CRC_FULLPANEL - [COLORECTAL_GENES_REGEX.match(colo_string)[0]]
                      neg_genes.each do |genes|
                        genocolorectal1 = genocolorectal.dup_colo
                        @logger.debug "SUCCESSFUL gene parse for negative test for: #{genes}"
                        genocolorectal1.add_status(1)
                        genocolorectal1.add_gene_colorectal(genes)
                        genocolorectal1.add_protein_impact(nil)
                        genocolorectal1.add_gene_location(nil)
                        genotypes.append(genocolorectal1)
                      end
                      genocolorectal.add_gene_colorectal($LAST_MATCH_INFO[:colorectal])
                      process_cdna_change(genocolorectal, record)
                      process_protein_impact(genocolorectal, record)
                      genocolorectal.add_status(2)
                      genotypes.append(genocolorectal)
                    else
                      CCP_CRC_FULLPANEL.each do |genes|
                        genocolorectal1 = genocolorectal.dup_colo
                        genocolorectal1.add_status(1)
                        genocolorectal1.add_gene_colorectal(genes)
                        genocolorectal1.add_protein_impact(nil)
                        genocolorectal1.add_gene_location(nil)
                        genotypes.append(genocolorectal1)
                      end
                    end
                  elsif karyo.scan(COLORECTAL_GENES_REGEX).size > 1
                    if COLORECTAL_GENES_REGEX.match(colo_string)
                      karyogenes = karyo.scan(COLORECTAL_GENES_REGEX).compact.flatten
                      matchedgenes = [COLORECTAL_GENES_REGEX.match(colo_string)[0]]
                      neg_genes = karyogenes - matchedgenes
                      neg_genes.each do |genes|
                        genocolorectal1 = genocolorectal.dup_colo
                        @logger.debug "SUCCESSFUL gene parse for negative test for: #{genes}"
                        genocolorectal1.add_status(1)
                        genocolorectal1.add_gene_colorectal(genes)
                        genocolorectal1.add_protein_impact(nil)
                        genocolorectal1.add_gene_location(nil)
                        genotypes.append(genocolorectal1)
                      end
                      genocolorectal.add_gene_colorectal($LAST_MATCH_INFO[:colorectal])
                      process_cdna_change(genocolorectal, record)
                      process_protein_impact(genocolorectal, record)
                      genocolorectal.add_status(2)
                      genotypes.append(genocolorectal)
                    else
                      karyo.scan(COLORECTAL_GENES_REGEX).compact.flatten.each do |genes|
                        genocolorectal1 = genocolorectal.dup_colo
                        genocolorectal1.add_status(1)
                        genocolorectal1.add_gene_colorectal(genes)
                        genocolorectal1.add_protein_impact(nil)
                        genocolorectal1.add_gene_location(nil)
                        genotypes.append(genocolorectal1)
                      end
                    end
                  end
                end
              end
            end
            genotypes
          end

          def process_cdna_change(genocolorectal, record)
            case record.raw_fields['genotype']
            when CDNA_REGEX
              genocolorectal.add_gene_location($LAST_MATCH_INFO[:cdna])
              @logger.debug "SUCCESSFUL cdna change parse for: #{$LAST_MATCH_INFO[:cdna]}"
            else
              @logger.debug "FAILED cdna change parse for: #{record.raw_fields['genocolorectal']}"
              @failed_genotype_counter += 1
            end
          end

          def process_teststatus(genocolorectal, record)
            case record.raw_fields['genotype']
            when /pathogenic/i
              genocolorectal.add_status(:negative)
              @negative_test += 1
            else
              genocolorectal.add_status(:positive)
              @positive_test += 1
            end
          end

          def process_protein_impact(genocolorectal, record)
            case record.raw_fields['genotype']
            when PROTEIN_REGEX
              genocolorectal.add_protein_impact($LAST_MATCH_INFO[:impact])
              @logger.debug "SUCCESSFUL protein change parse for: #{$LAST_MATCH_INFO[:impact]}"
            else
              @logger.debug "FAILED protein change parse for: #{record.raw_fields['genocolorectal']}"
            end
          end

          def process_gene(genocolorectal, record)
            #   | unless record.raw_fields['karyotypingmethod'].nil?
            # unless record.raw_fields['karyotypingmethod'].nil?
            if COLORECTAL_GENES_REGEX.match(record.raw_fields['genotype'])
              genocolorectal.add_gene_colorectal($LAST_MATCH_INFO[:colorectal])
              @successful_gene_counter += 1
              @gene_counter += 1
              @logger.debug "SUCCESSFUL gene parse for: #{$LAST_MATCH_INFO[:colorectal]}"
            else
              @logger.debug "FAILED gene parse for genotype #{record.raw_fields['genotype']}"
              @failed_gene_counter += 1
              @gene_counter += 1
            end
          end

          def process_exons(genotype_string, genocolorectal)
            exon_matches = EXON_LOCATION_REGEX.match(genotype_string)
            if exon_matches
              genocolorectal.add_exon_location(exon_matches[1].delete(' '))
              genocolorectal.add_variant_type(genotype_string)
              @logger.debug "SUCCESSFUL exon extraction for: #{genotype_string}"
            else
              @logger.warn "Cannot extract exon from: #{genotype_string}"
            end
          end

          def summarize
            @logger.info '***************** Handler Report *******************'
            @logger.info "Num genes failed to parse: #{@failed_gene_counter} of "\
                         "#{@persister.genetic_tests.values.flatten.size} tests being attempted"
            @logger.info "Num genes successfully parsed: #{@successful_gene_counter} of"\
                          "#{@persister.genetic_tests.values.flatten.size} attempted"
            @logger.info "Num genotypes failed to parse: #{@failed_genotype_counter}"\
                         "of #{@lines_processed} attempted"
            @logger.info "Num positive tests: #{@positive_test}"\
                          "of #{@persister.genetic_tests.values.flatten.size} attempted"
            @logger.info "Num negative tests: #{@negative_test}"\
                          "of #{@persister.genetic_tests.values.flatten.size} attempted"
          end

        end
      end
    end
  end
end
