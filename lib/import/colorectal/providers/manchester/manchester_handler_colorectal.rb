require 'possibly'
require 'import/storage_manager/persister'
require 'pry'
require 'import/brca/core/provider_handler'

module Import
  module Colorectal
    module Providers
      module Manchester
        class ManchesterHandlerColorectal < Import::Brca::Core::ProviderHandler
          PASS_THROUGH_FIELDS_COLO = %w[age consultantcode servicereportidentifier providercode
                                        authoriseddate requesteddate practitionercode genomicchange
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
                                                STK11)/xi . freeze # Added by

          MOLTEST_MAP = { "HNPCC (hMSH6) MUTATION SCREENING REPORT" => "MSH6", 
                         "HNPCC (MSH6) MUTATION SCREENING REPORT" => "MSH6",
                         "HNPCC CONFIRMATORY TESTING REPORT" => %w[MLH1 MSH2 MSH6],
                         "HNPCC MSH2 c.942+3A>T MUTATION TESTING REPORT" => "MSH2",
                         "HNPCC MUTATION SCREENING REPORT" => %w[MLH1 MSH2],
                         "HNPCC PREDICTIVE REPORT" => %w[MLH1 MSH2 MSH6],
                         "HNPCC PREDICTIVE TESTING REPORT" => %w[MLH1 MSH2 MSH6],
                         "LYNCH SYNDROME (@gene) - PREDICTIVE TESTING REPORT" => %w[MLH1 MSH2 MSH6],
                         "LYNCH SYNDROME (hMSH6) MUTATION SCREENING REPORT" => "MSH6",
                         "LYNCH SYNDROME (MLH1) - PREDICTIVE TESTING REPORT" => %w[MLH1 MSH2 MSH6],
                         "LYNCH SYNDROME (MLH1/MSH2) MUTATION SCREENING REPORT" => %w[MLH1 MSH2],
                         "LYNCH SYNDROME (MSH2) - PREDICTIVE TESTING REPORT" => "MSH2",
                         "LYNCH SYNDROME (MSH6) - PREDICTIVE TESTING REPORT" => "MSH6",
                         "LYNCH SYNDROME (MSH6) MUTATION SCREENING REPORT" => "MSH6",
                         "LYNCH SYNDROME CONFIRMATORY TESTING REPORT" => %w[MLH1 MSH2 MSH6],
                         "LYNCH SYNDROME GENE SCREENING REPORT" => %w[MLH1 MSH2 MSH6],
                         "LYNCH SYNDROME MUTATION SCREENING REPORT" => %w[MLH1 MSH2 MSH6],
                         "LYNCH SYNDROME SCREENING REPORT" => %w[MLH1 MSH2 MSH6],
                         "MLH1/MSH2/MSH6 GENE SCREENING REPORT" => %w[MLH1 MSH2 MSH6],
                         "MLH1/MSH2/MSH6 GENETIC TESTING REPORT" => %w[MLH1 MSH2 MSH6],
                         "MSH6 PREDICTIVE TESTING REPORT" => "MSH6",
                         "RARE DISEASE SERVICE - PREDICTIVE TESTING REPORT" => %w[MLH1 MSH2 MSH6],
                         "VARIANT TESTING REPORT" => %w[MLH1 MSH2 MSH6] }

          MOLTEST_MAP_DOSAGE = { "HNPCC DOSAGE ANALYSIS REPORT" => %w[MLH1 MSH2 MSH6],
           "MSH6  DOSAGE ANALYSIS REPORT" =>"MSH6",
           "LYNCH SYNDROME DOSAGE ANALYSIS REPORT" => %w[MLH1 MSH2 MSH6],
           "LYNCH SYNDROME DOSAGE ANALYSIS - PREDICTIVE TESTING REPORT" => %w[MLH1 MSH2 MSH6],
           "LYNCH SYNDROME (MSH6) DOSAGE ANALYSIS REPORT" => "MSH6"}

          CDNA_REGEX = /c\.(?<cdna>[0-9]+[a-z]+\>[a-z]+)|
                       c\.(?<cdna>[0-9]+.[0-9]+[a-z]+>[a-z]+)|
                       c\.(?<cdna>[0-9]+_[0-9]+[a-z]+)|
                       c\.(?<cdna>[0-9]+[a-z]+)|
                       c\.(?<cdna>.+\s[a-z]>[a-z])|
                       c\.(?<cdna>[0-9]+_[0-9]+\+[0-9]+[a-z]+)/ix .freeze

          PROT_REGEX = /p\.(\()?(?<impact>[a-z]+[0-9]+[a-z]+)(\))?/i .freeze
          EXON_REGEX = /(?<insdeldup>ins|del|dup)/i .freeze
          EXON_LOCATION_REGEX = /ex(?<exon>[\d]+)(.[\d]+)?(\sto\s)?(ex(?<exon2>[\d]+))?/i .freeze

          def initialize(batch)
            @failed_genocolorectal_counter = 0
            @successful_gene_counter = 0
            @failed_gene_counter = 0
            @negative_test = 0
            @positive_test = 0
            super
          end

          def process_fields(record)

            global_genotype_col = []
            global_genotype2_col = []
            global_genus_col= []
            global_moltesttype_col = []
            global_exon_col = []

            dosage_genotype_col = []
            dosage_genotype2_col = []
            dosage_genus_col= []
            dosage_moltesttype_col = []
            dosage_exon_col = []
          
            record.raw_fields.map {|records|
              if records["exon"] =~ /mlpa/i and \
                records["genocomm"] !~ /control|ctrl/i .freeze and\
                records["consultantname"] != "Dr Sandi Deans"
                dosage_genus_col.append(records["genus"])
                dosage_moltesttype_col.append(records["moleculartestingtype"])
                dosage_exon_col.append(records["exon"])
                dosage_genotype_col.append(records["genotype"])
                dosage_genotype2_col.append(records["genotype2"])
              elsif records["genocomm"] !~ /control|ctrl/i .freeze and \
                records["consultantname"] != "Dr Sandi Deans"
                global_genus_col.append(records["genus"])
                global_moltesttype_col.append(records["moleculartestingtype"])
                global_exon_col.append(records["exon"])
                global_genotype_col.append(records["genotype"])
                global_genotype2_col.append(records["genotype2"])
              else
                break
              end }

            # record.raw_fields.map {|records|
            #                         if records["genocomm"] !~ /control|ctrl/i .freeze and \
            #                           records["consultantname"] != "Dr Sandi Deans"
            #                           global_genus_col.append(records["genus"])
            #                           global_moltesttype_col.append(records["moleculartestingtype"])
            #                           global_exon_col.append(records["exon"])
            #                           global_genotype_col.append(records["genotype"])
            #                           global_genotype2_col.append(records["genotype2"])
            #                         else
            #                           break
            #                         end }
            #
            # record.raw_fields.map {|records|
            #                         if records["exon"] =~ /mlpa/i and \
            #                           records["genocomm"] !~ /control|ctrl/i .freeze and\
            #                           records["consultantname"] != "Dr Sandi Deans"
            #                           dosage_genus_col.append(records["genus"])
            #                           dosage_moltesttype_col.append(records["moleculartestingtype"])
            #                           dosage_exon_col.append(records["exon"])
            #                           dosage_genotype_col.append(records["genotype"])
            #                           dosage_genotype2_col.append(records["genotype2"])
            #                         else
            #                           break
            #                         end }

            @global_record_map = { genus: global_genus_col,
                           moleculartestingtype: global_moltesttype_col,
                           exon: global_exon_col,
                           genotype: global_genotype_col,
                           genotype2: global_genotype2_col }

           @dosage_record_map = { genus: dosage_genus_col,
                          moleculartestingtype: dosage_moltesttype_col,
                          exon: dosage_exon_col,
                          genotype: dosage_genotype_col,
                          genotype2: dosage_genotype2_col }

            @stringed_moltesttype = @global_record_map[:moleculartestingtype].flatten.join(',')
            @stringed_exon = @global_record_map[:exon].flatten.join(',')

            @lines_processed += 1 # TODO: factor this out to be automatic across handlers
            genocolorectal = Import::Colorectal::Core::Genocolorectal.new(record)
            genocolorectal.add_passthrough_fields(record.mapped_fields,
                                                  record.raw_fields,
                                                  PASS_THROUGH_FIELDS_COLO)

            add_servicereportidentifier(genocolorectal, record)
            testscope_from_rawfields(genocolorectal, record)
            res = assign_gene_mutation(genocolorectal, record) # Added by Francesco
            res.map { |cur_genotype| @persister.integrate_and_store(cur_genotype) }
          end

          def add_servicereportidentifier(genocolorectal, record)
            servicereportidentifier_array = []
            record.raw_fields.map {|records| servicereportidentifier_array.append(records["servicereportidentifier"])}
            genocolorectal.attribute_map["servicereportidentifier"] = servicereportidentifier_array.flatten.uniq.join()
          end


          def testscope_from_rawfields(genocolorectal, record)
            moltesttype = []
            genus = []
            exon=[]
            record.raw_fields.map do |records| 
              moltesttype.append(records["moleculartestingtype"])
              genus.append(records["genus"])
              exon.append(records["exon"])
            end
            stringed_moltesttype = moltesttype.flatten.join(',')
            stringed_exon = exon.flatten.join(',')
            if stringed_moltesttype =~ /predictive|confirm/i
              genocolorectal.add_test_scope(:targeted_mutation)
            elsif genus.include? "G" or genus.include? "F"
              genocolorectal.add_test_scope(:full_screen)
            elsif (stringed_moltesttype =~ /screen/i or \
            moltesttype.include? "MLH1/MSH2/MSH6 GENETIC TESTING REPORT") and
            moltesttype.size >= 12
              genocolorectal.add_test_scope(:full_screen)
            elsif (stringed_moltesttype =~ /screen/i or \
            moltesttype.include? "MLH1/MSH2/MSH6 GENETIC TESTING REPORT") and
            moltesttype.size <= 12 and stringed_exon =~ /ngs/i
              genocolorectal.add_test_scope(:full_screen)
            elsif (stringed_moltesttype =~ /screen/i or \
            moltesttype.include? "MLH1/MSH2/MSH6 GENETIC TESTING REPORT") and
            moltesttype.size <= 12 and stringed_exon !~ /ngs/i 
              genocolorectal.add_test_scope(:targeted_mutation)
            elsif moltesttype.include? "VARIANT TESTING REPORT" 
              genocolorectal.add_test_scope(:targeted_mutation)
            elsif stringed_moltesttype =~ /dosage/i
              genocolorectal.add_test_scope(:full_screen)
            elsif moltesttype.include? "HNPCC MSH2 c.942+3A>T MUTATION TESTING REPORT"
              genocolorectal.add_test_scope(:full_screen)
            end
          end

          def assign_gene_mutation(genocolorectal,record)
            genotypes = []
            genes = []
            if (MOLTEST_MAP.keys & @global_record_map[:moleculartestingtype].uniq).size == 1
              @global_record_map[:exon].map {|exons|
                if exons =~ COLORECTAL_GENES_REGEX
                  genes.append(COLORECTAL_GENES_REGEX.match(exons)[:colorectal])
                else
                  genes.append("No Gene")
                end }
              tests = genes.zip(@global_record_map[:genotype],
                                @global_record_map[:genotype2]).uniq unless genes.nil?

              grouped_tests = tests.group_by {|test| test.shift}.transform_values do |values| 
                values.flatten.uniq
              end
              selected_genes = (@global_record_map[:moleculartestingtype].uniq & MOLTEST_MAP.keys).join()

              grouped_tests.each {
                |gene,genetic_info| 
                if selected_genes == ""
                  @logger.debug("Nothing to do")
                  break
                elsif MOLTEST_MAP[selected_genes].include? gene
                  genocolorectal1 = genocolorectal.dup_colo
                  if CDNA_REGEX.match(genetic_info.join(','))
                    if COLORECTAL_GENES_REGEX.match(genetic_info.join(','))
                      if COLORECTAL_GENES_REGEX.match(genetic_info.join(','))[:colorectal] != gene
                        @logger.debug("IDENTIFIED FALSE POSITIVE FOR #{gene}, #{COLORECTAL_GENES_REGEX.match(genetic_info.join(','))[:colorectal]}, #{CDNA_REGEX.match(genetic_info.join(','))[:cdna]} from #{genetic_info}")
                      elsif COLORECTAL_GENES_REGEX.match(genetic_info.join(','))[:colorectal] == gene
                        @logger.debug("IDENTIFIED TRUE POSITIVE FOR #{gene}, #{CDNA_REGEX.match(genetic_info.join(','))[:cdna]} from #{genetic_info}")
                        genocolorectal1.add_gene_location(CDNA_REGEX.match(genetic_info.join(','))[:cdna])
                        if PROT_REGEX.match(genetic_info.join(','))
                          @logger.debug("IDENTIFIED #{PROT_REGEX.match(genetic_info.join(','))[:impact]} from #{genetic_info}")
                          genocolorectal1.add_protein_impact(PROT_REGEX.match(genetic_info.join(','))[:impact])
                        end
                        genocolorectal1.add_gene_colorectal(gene)
                        @logger.debug("IDENTIFIED #{gene}, POSITIVE TEST from #{genetic_info}")
                        genocolorectal1.add_status(2)
                        genotypes.append(genocolorectal1)
                      end
                    else
                      @logger.debug("IDENTIFIED #{gene}, #{CDNA_REGEX.match(genetic_info.join(','))[:cdna]} from #{genetic_info}")
                      genocolorectal1.add_gene_location(CDNA_REGEX.match(genetic_info.join(','))[:cdna])
                      if PROT_REGEX.match(genetic_info.join(','))
                        @logger.debug("IDENTIFIED #{PROT_REGEX.match(genetic_info.join(','))[:impact]} from #{genetic_info}")
                        genocolorectal1.add_protein_impact(PROT_REGEX.match(genetic_info.join(','))[:impact])
                      end
                      genocolorectal1.add_gene_colorectal(gene)
                      @logger.debug("IDENTIFIED #{gene}, POSITIVE TEST from #{genetic_info}")
                      genocolorectal1.add_status(2)
                      genotypes.append(genocolorectal1)
                    end
                  elsif genetic_info.join(',') !~ CDNA_REGEX and genetic_info.join(',') =~ /normal/i
                    genocolorectal1 = genocolorectal.dup_colo
                    @logger.debug("IDENTIFIED #{gene}, NORMAL TEST from #{genetic_info}")
                    genocolorectal1.add_gene_colorectal(gene)
                    genocolorectal1.add_status(1)
                    genotypes.append(genocolorectal1)
                  elsif genetic_info.join(',') !~ CDNA_REGEX and genetic_info.join(',') !~ /normal/i and genetic_info.join(',') =~ /fail/i
                    genocolorectal1 = genocolorectal.dup_colo
                    genocolorectal1.add_gene_colorectal(gene)
                    @logger.debug("Adding #{gene} to FAIL STATUS for #{genetic_info}")
                    genocolorectal1.add_status(9)
                    genotypes.append(genocolorectal1)
                  end
                end
              }
            elsif (MOLTEST_MAP_DOSAGE.keys & @dosage_record_map[:moleculartestingtype].uniq).size == 1
              @dosage_record_map[:exon].map {|exons|
                if exons.scan(COLORECTAL_GENES_REGEX).size > 0 and exons =~ /mlpa/i
                  exons.scan(COLORECTAL_GENES_REGEX).flatten.each {|gene| genes.append(gene)}
                else
                  genes.append("No Gene")
                end}
              tests = genes.zip(@dosage_record_map[:genotype],
                                @dosage_record_map[:genotype2],
                                @dosage_record_map[:moleculartestingtype]).uniq unless genes.nil?

              grouped_tests = tests.group_by {|test| test.shift}.transform_values do |values| 
                values.flatten.uniq
              end
              selected_genes = (@dosage_record_map[:moleculartestingtype].uniq & MOLTEST_MAP_DOSAGE.keys).join()
              grouped_tests.compact.select {|gene,genetic_info| 
                if selected_genes == ""
                  @logger.debug("Nothing to do")
                  break
                elsif MOLTEST_MAP_DOSAGE[selected_genes].include? gene
                  if genetic_info.join(',') !~ COLORECTAL_GENES_REGEX
                    genocolorectal1 = genocolorectal.dup_colo
                    genocolorectal1.add_gene_colorectal(gene)
                    genocolorectal1.add_status(1)
                    genotypes.append(genocolorectal1)
                    @logger.debug("IDENTIFIED #{gene} from #{MOLTEST_MAP_DOSAGE[selected_genes]}, NORMAL TEST from #{genetic_info}")
                  elsif genetic_info.join(',') =~ COLORECTAL_GENES_REGEX and \
                    genetic_info.join(',') !~ EXON_REGEX
                    genocolorectal1 = genocolorectal.dup_colo
                    genocolorectal1.add_gene_colorectal(gene)
                    genocolorectal1.add_status(1)
                    genotypes.append(genocolorectal1)
                    @logger.debug("IDENTIFIED #{gene} from #{MOLTEST_MAP_DOSAGE[selected_genes]}, NORMAL TEST from #{genetic_info}")
                  elsif genetic_info.join(',') =~ COLORECTAL_GENES_REGEX and \
                    genetic_info.join(',') =~ EXON_REGEX
                    genocolorectal1 = genocolorectal.dup_colo
                    genocolorectal1.add_gene_colorectal(COLORECTAL_GENES_REGEX.match(genetic_info.join(','))[:colorectal])
                    genocolorectal1.add_variant_type(EXON_REGEX.match(genetic_info.join(','))[:insdeldup])
                    if EXON_LOCATION_REGEX.match(genetic_info.join(','))
                      if genetic_info.join(',').scan(EXON_LOCATION_REGEX).size == 1
                        genocolorectal1.add_exon_location(genetic_info.join(',').scan(EXON_LOCATION_REGEX).flatten[0])
                      elsif genetic_info.join(',').scan(EXON_LOCATION_REGEX).size == 2
                        genocolorectal1.add_exon_location(genetic_info.join(',').scan(EXON_LOCATION_REGEX).flatten.compact.join('-'))
                      end
                    end
                    genocolorectal1.add_status(2)
                    genotypes.append(genocolorectal1)
                  end
                else 
                  @logger.debug("Nothing to be done for #{gene} as it is not in #{selected_genes}")
                end }
            end
            genotypes
          end

        end
      end
    end
  end
end