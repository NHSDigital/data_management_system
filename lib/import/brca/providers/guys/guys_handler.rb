require 'possibly'

module Import
  module Brca
    module Providers
      module Guys
        # Process Guys/St Thomas-specific record details into generalized internal genotype format
        class GuysHandler < Import::Brca::Core::ProviderHandler
          include Import::Helpers::Brca::Providers::Rj1::Rj1Constants

          PASS_THROUGH_FIELDS = %w[age receiveddate sortdate requesteddate
                                   requesteddate
                                   servicereportidentifier
                                   consultantcode
                                   providercode] .freeze

          def process_fields(record)
            genotype = Import::Brca::Core::GenotypeBrca.new(record)
            genotype.add_passthrough_fields(record.mapped_fields,
                                            record.raw_fields,
                                            PASS_THROUGH_FIELDS)
            @genotype   = genotype
            @record     = record
            @genotypes  = []
            @aj_report_date = record.raw_fields['ashkenazi assay report date']
            @aj_assay_result = record.raw_fields['ashkenazi assay result']
            @predictive_report_date = record.raw_fields['predictive report date']
            @brca1_mutation = record.raw_fields['brca1 mutation']
            @brca2_mutation = record.raw_fields['brca2 mutation']
            @polish_report_date = record.raw_fields['polish assay report date']
            @polish_assay_result = record.raw_fields['polish assay result']
            @predictive_report_date = record.raw_fields['predictive report date']
            @authoriseddate = record.raw_fields['authoriseddate']
            @predictive = record.raw_fields['predictive']
            @ngs_result = record.raw_fields['ngs result']
            @ngs_report_date = record.raw_fields['ngs report date']
            @fullscreen_result = record.raw_fields['full screen result']
            @brca1_mlpa_result = record.raw_fields['brca1 mlpa results']
            @brca2_mlpa_result = record.raw_fields['brca2 mlpa results']
            @brca1_seq_result = record.raw_fields['brca1 seq result']
            @brca2_seq_result = record.raw_fields['brca2 seq result']
              
            mtype = record.raw_fields['moleculartestingtype']
            genotype.add_molecular_testing_type_strict(mtype) if mtype
            add_organisationcode_testresult(genotype)
            res = process_tests unless process_tests.empty? || process_tests.nil?
            res.flatten.each { |cur_genotype| @persister.integrate_and_store(cur_genotype) } unless res.nil?
          end



          def add_organisationcode_testresult(genotype)
            genotype.attribute_map['organisationcode_testresult'] = '699L0'
          end

          def process_tests
            results = []
            METHODS_MAP.each do |condition_extraction|
              condition, extraction = *condition_extraction
              results << send(extraction) if send(condition)
            end
            results.compact
          end

          #####################################################################################
          ################ HERE ARE COMMON METHODS ############################################
          #####################################################################################

          def brca1_mutation?
            return if @brca1_mutation.nil?
            @brca1_mutation.scan(CDNA_REGEX).size.positive?
          end
          
          def brca2_mutation?
            return if @brca2_mutation.nil?
            @brca2_mutation.scan(CDNA_REGEX).size.positive?
          end

          def normal_brca1_seq?
            return if @brca1_seq_result.nil?
            @brca1_seq_result.downcase == '-ve' ||
            @brca1_seq_result.downcase == 'neg' ||
            @brca1_seq_result.downcase == 'nrg' ||
            @brca1_seq_result.scan(/neg|nrg|norm/i).size.positive? ||
            @brca1_seq_result.scan(/no mut/i).size.positive? ||
            @brca1_seq_result.scan(/no var|no fam|not det/i).size.positive? 
          end

          def normal_brca2_seq?
            return if @brca2_seq_result.nil?
            @brca2_seq_result.downcase == '-ve' ||
            @brca2_seq_result.downcase == 'neg' ||
            @brca2_seq_result.downcase == 'nrg' ||
            @brca2_seq_result.scan(/neg|nrg|norm/i).size.positive?||
            @brca2_seq_result.scan(/no mut/i).size.positive? ||
            @brca2_seq_result.scan(/no var|no fam|not det/i).size.positive? 
          end
          def normal_brca1_mlpa_targeted_test?
            return if @brca1_mlpa_result.nil? || @brca1_mlpa_result == "N/A"
            @brca1_mlpa_result.scan(/no del\/dup/i).size.positive?
          end

          def normal_brca2_mlpa_targeted_test?
            return if @brca2_mlpa_result.nil? || @brca2_mlpa_result == "N/A"
            @brca2_mlpa_result.scan(/no del\/dup/i).size.positive?
          end

          def failed_brca1_mlpa_targeted_test?
            return if @brca1_mlpa_result.nil? || @brca1_mlpa_result == "N/A"
            @brca1_mlpa_result.scan(/fail/i).size.positive?
          end

          def failed_brca2_mlpa_targeted_test?
            return if @brca2_mlpa_result.nil? || @brca2_mlpa_result == "N/A"
            @brca2_mlpa_result.scan(/fail/i).size.positive?
          end

          def positive_seq_brca1?
            return if @brca1_seq_result.nil?
            @brca1_seq_result.scan(CDNA_REGEX).size.positive?
          end

          def positive_seq_brca2?
            return if @brca2_seq_result.nil?
            @brca2_seq_result.scan(CDNA_REGEX).size.positive?
          end

          def process_negative_gene(negative_gene, test_scope)
            negative_genotype = @genotype.dup
            negative_genotype.add_gene(negative_gene)
            negative_genotype.add_status(1)
            negative_genotype.add_test_scope(test_scope)
            @genotypes.append(negative_genotype)
          end

          def process_failed_gene(failed_gene, test_scope)
            failed_genotype = @genotype.dup
            failed_genotype.add_gene(failed_gene)
            failed_genotype.add_status(9)
            failed_genotype.add_test_scope(test_scope)
            @genotypes.append(failed_genotype)
          end

          def process_double_brca_negative(test_scope)
            ['BRCA1', 'BRCA2'].each do |negative_gene| 
              genotype1 = @genotype.dup
              genotype1.add_gene(negative_gene)
              genotype1.add_status(1)
              genotype1.add_test_scope(test_scope)
              @genotypes.append(genotype1)
            end
            @genotypes
          end

          def process_double_brca_negative(test_scope)
            ['BRCA1', 'BRCA2'].each do |negative_gene| 
              genotype1 = @genotype.dup
              genotype1.add_gene(negative_gene)
              genotype1.add_status(1)
              genotype1.add_test_scope(test_scope)
              @genotypes.append(genotype1)
            end
            @genotypes
          end

          def process_double_brca_fail(test_scope)
            ['BRCA1', 'BRCA2'].each do |unknown_gene_test| 
              genotype1 = @genotype.dup
              genotype1.add_gene(unknown_gene_test)
              genotype1.add_status(9)
              genotype1.add_test_scope(test_scope)
              @genotypes.append(genotype1)
            end
            @genotypes
          end

          def process_double_brca_unknown(test_scope)
            ['BRCA1', 'BRCA2'].each do |unknown_gene_test| 
              genotype1 = @genotype.dup
              genotype1.add_gene(unknown_gene_test)
              genotype1.add_status(4)
              genotype1.add_test_scope(test_scope)
              @genotypes.append(genotype1)
            end
            @genotypes
          end

          def process_positive_cdnavariant(positive_gene, cdna_variant, test_scope)
            positive_genotype = @genotype.dup
            positive_genotype.add_gene(positive_gene)
            positive_genotype.add_gene_location(cdna_variant)
            positive_genotype.add_status(2)
            positive_genotype.add_test_scope(test_scope)
            @genotypes.append(positive_genotype)
          end

          def process_positive_exonvariant(positive_gene, exon_variant, test_scope)
            positive_genotype = @genotype.dup
            positive_genotype.add_gene(positive_gene)
            add_zygosity_from_exonicvariant(exon_variant, positive_genotype)
            add_varianttype_from_exonicvariant(exon_variant, positive_genotype)
            add_involved_exons_from_exonicvariant(exon_variant, positive_genotype)
            positive_genotype.add_status(2)
            positive_genotype.add_test_scope(test_scope)
            @genotypes.append(positive_genotype)
          end

          def add_zygosity_from_exonicvariant(exon_variant, positive_genotype)
            Maybe(exon_variant[:zygosity]).map { |x| positive_genotype.add_zygosity(x) }
          rescue StandardError
            @logger.debug 'Cannot add exon variant zygosity'
          end

          def add_varianttype_from_exonicvariant(exon_variant, positive_genotype)
            Maybe(exon_variant[:deldup]).map { |x| positive_genotype.add_variant_type(x) }
          rescue StandardError
            @logger.debug 'Cannot add exon variant type'
          end

          def add_involved_exons_from_exonicvariant(exon_variant, positive_genotype)
            Maybe(exon_variant[:exons]).map { |x| positive_genotype.add_exon_location(x) }
          rescue StandardError
            @logger.debug 'Cannot add exons involved in exonic variant'
          end




          #####################################################################################
          ################ HERE ARE ASHKENAZI TESTS ###########################################
          #####################################################################################
          
          def ashkenazi_test?
            @aj_report_date.present? || @aj_assay_result.present?
          end
          
          def normal_ashkenazi_test?
            return if @aj_assay_result.nil?

            @aj_assay_result.scan(/neg|nrg/i).size.positive? &&
            @brca1_mutation.nil? && @brca2_mutation.nil?
          end

          def positive_ashkenazi_test?
            return if @aj_assay_result.nil?

            @aj_assay_result.scan(/neg|nrg/i).size.zero?
          end

          def normal_ashkkenazi_test?
            @aj_assay_result.downcase == "mutation not detected" ||
            @aj_assay_result.downcase == "neg"||
            @aj_assay_result.downcase == "nrg" ||
            @aj_assay_result.downcase == "no mutation" ||
            @aj_assay_result.downcase == "no variant" ||
            @aj_assay_result.downcase == 'no variants detected'||
            @aj_assay_result.scan(/neg|nrg/i).size.positive?
          end
          
          def process_ashkenazi_test
            return if @aj_assay_result.nil?

            if normal_ashkkenazi_test?
               process_double_brca_negative(:aj_screen)
            elsif brca1_mutation? || brca2_mutation?
              if brca1_mutation? & !brca2_mutation?
                process_positive_cdnavariant('BRCA1',@brca1_mutation.match(CDNA_REGEX)[:cdna], :aj_screen)
                process_negative_gene('BRCA2', :aj_screen)
              elsif brca2_mutation? & !brca1_mutation?
                process_positive_cdnavariant('BRCA2',@brca2_mutation.match(CDNA_REGEX)[:cdna], :aj_screen)
                process_negative_gene('BRCA1', :aj_screen)
              elsif brca2_mutation? & brca1_mutation?
                process_positive_cdnavariant('BRCA2',@brca2_mutation.match(CDNA_REGEX)[:cdna], :aj_screen)
                process_positive_cdnavariant('BRCA1',@brca1_mutation.match(CDNA_REGEX)[:cdna], :aj_screen)
              end
              @genotypes
            elsif brca1_mutation_exception? || @aj_assay_result == "68_69delAG"
              if @aj_assay_result == "68_69delAG"
                process_positive_cdnavariant('BRCA1','68_69delAG', :aj_screen)
                process_negative_gene('BRCA2', :aj_screen)
              else
                process_positive_cdnavariant('BRCA1',@aj_assay_result.match(CDNA_REGEX)[:cdna], :aj_screen)
                process_negative_gene('BRCA2', :aj_screen)
              end
              @genotypes
            elsif brca2_mutation_exception?
               process_positive_cdnavariant('BRCA2',@aj_assay_result.match(CDNA_REGEX)[:cdna], :aj_screen) 
               process_negative_gene('BRCA1', :aj_screen)
            end
            @genotypes
          end
          
          def brca1_mutation_exception?
            # @aj_assay_result == "68_69delAG" ||
            BRCA1_MUTATIONS.include? @aj_assay_result
          end

          def brca2_mutation_exception?
            BRCA2_MUTATIONS.include? @aj_assay_result
          end
          
          #####################################################################################
          ################ HERE ARE POLISH TESTS ##############################################
          #####################################################################################
          
          def polish_test?
            @polish_report_date.present? || @polish_assay_result.present?
          end

          def normal_polish_test?
            @polish_assay_result.downcase == "mutation not detected" ||
            @polish_assay_result.downcase == "neg"||
            @polish_assay_result.downcase == "nrg" ||
            @polish_assay_result.downcase == "no mutation" ||
             @polish_assay_result.downcase == "no mutations" ||
            @polish_assay_result.downcase == "no variant" ||
            @polish_assay_result.downcase == 'no variants detected'||
            @polish_assay_result.scan(/neg|nrg/i).size.positive?
          end
          
          def process_polish_test
            return if @polish_assay_result.nil?

            if normal_polish_test?
               process_negative_gene('BRCA1', :polish_screen)
            elsif @polish_assay_result.scan(CDNA_REGEX).size.positive?
              process_positive_cdnavariant('BRCA1',@polish_assay_result.match(CDNA_REGEX)[:cdna], :polish_screen)
            end
            @genotypes
          end
          
          #####################################################################################
          ################ HERE ARE TARGETED TESTS ############################################
          #####################################################################################
          
          def targeted_test_first_option?
            @predictive_report_date.present? && @aj_assay_result.nil? && @polish_assay_result.nil?
          end

          def targeted_test_second_option?
            return if @aj_assay_result.nil?
            @predictive_report_date.present? &&
            @aj_assay_result.scan(/neg|nrg/i).size.positive? &&
            (@brca1_mutation.present? || @brca2_mutation.present? ||
            @brca1_mlpa_result.present? || @brca2_mlpa_result.present?)
          end
          
          def targeted_test_third_option?
            return if @polish_assay_result.nil?
            @predictive_report_date.present? &&
            @polish_assay_result.scan(/neg|nrg/i).size.positive? &&
            (@brca1_mutation.present? || @brca2_mutation.present? ||
            @brca1_mlpa_result.present? || @brca2_mlpa_result.present?)
          end
          
          def targeted_test_fourth_option?
            return if @predictive.nil?
            @predictive_report_date.nil? && @predictive.scan(/true/i).size.positive? &&
            @ngs_result.nil? &&
            @polish_assay_result.nil? && @aj_assay_result.nil? && @fullscreen_result.nil?
          end

          def positive_mlpa_brca1_targeted_test?
            return if @brca1_mlpa_result.nil?
            @authoriseddate.nil? && @brca1_mlpa_result.scan(EXON_REGEX).size.positive?
          end

          def positive_mlpa_brca2_targeted_test?
            return if @brca2_mlpa_result.nil?
            @authoriseddate.nil? && @brca2_mlpa_result.scan(EXON_REGEX).size.positive?
          end

          def positive_exonvariants_in_set_brca1_targeted_test?
            return if @brca1_seq_result.nil?
            @authoriseddate.nil? && @brca1_seq_result.scan(EXON_REGEX).size.positive?
          end

          def positive_exonvariants_in_set_brca2_targeted_test?
            return if @brca2_seq_result.nil?
            @authoriseddate.nil? && @brca2_seq_result.scan(EXON_REGEX).size.positive?
          end

          def all_null_results_targeted_test?
            @brca1_seq_result.nil? && @brca2_seq_result.nil? &&
            @brca1_mpa_result.nil? && @brca2_mlpa_result.nil?
          end
          
          
          def process_all_null_results_targeted_test(test_scope)
            unknown_genotype = @genotype.dup
            unknown_genotype.add_status(9)
            unknown_genotype.add_test_scope(test_scope)
            @genotypes.append(unknown_genotype)
          end
          
          def process_normal_brca1_2_seq_targeted_tests
            if normal_brca1_seq?
              process_negative_gene('BRCA1', :targeted_mutation)
            elsif normal_brca2_seq?
              process_negative_gene('BRCA2', :targeted_mutation)
            end
            @genotypes
          end

          def process_normal_brca1_2_mlpa_targeted_tests
            if normal_brca1_mlpa_targeted_test?
              process_negative_gene('BRCA1', :targeted_mutation)
            elsif normal_brca2_mlpa_targeted_test?
              process_negative_gene('BRCA2', :targeted_mutation)
            end
            @genotypes
          end
          
          def process_failed_brca1_2_targeted_tests
            if failed_brca1_mlpa_targeted_test?
              process_failed_gene('BRCA1', :targeted_mutation)
            elsif failed_brca1_mlpa_targeted_test?
              process_failed_gene('BRCA2', :targeted_mutation)
            end
            @genotypes
          end

          def process_positive_brca1_2_seq_targeted_tests
            if positive_seq_brca1?
              process_positive_cdnavariant('BRCA1',@brca1_seq_result.match(CDNA_REGEX)[:cdna], 
                                         :targeted_mutation)
            elsif brca1_mutation?
              process_positive_cdnavariant('BRCA1',@brca1_mutation.match(CDNA_REGEX)[:cdna], 
                                            :targeted_mutation)
            elsif positive_seq_brca2?
              process_positive_cdnavariant('BRCA2',@brca2_seq_result.match(CDNA_REGEX)[:cdna], 
                                        :targeted_mutation)
            elsif brca2_mutation?
              process_positive_cdnavariant('BRCA1',@brca2_mutation.match(CDNA_REGEX)[:cdna], 
                                            :targeted_mutation)
            end
            @genotypes
          end
          
          def process_positive_brca1_2_mlpa_targeted_tests
            return if @brca1_mlpa_result.nil? && @brca2_mlpa_result.nil?

            if positive_mlpa_brca1_targeted_test?
              process_positive_exonvariant('BRCA1', @brca1_mlpa_result.match(EXON_REGEX), :targeted_mutation)
            elsif positive_exonvariants_in_set_brca1_targeted_test?
               process_positive_exonvariant('BRCA1', @brca1_seq_result.match(EXON_REGEX), :targeted_mutation)
            elsif positive_mlpa_brca2_targeted_test?
              process_positive_exonvariant('BRCA2', @brca2_mlpa_result.match(EXON_REGEX), :targeted_mutation)
            elsif positive_exonvariants_in_set_brca2_targeted_test?
              process_positive_exonvariant('BRCA2', @brca2_seq_result.match(EXON_REGEX), :targeted_mutation)
            end
            @genotypes
          end
          
          def process_targeted_test
            
            if all_null_results_targeted_test?
              process_all_null_results_targeted_test(:targeted_mutation)
            elsif normal_brca1_seq? || 
            normal_brca2_seq?
             process_normal_brca1_2_seq_targeted_tests
            elsif positive_seq_brca1? ||
              brca1_mutation?||
              positive_seq_brca2?||
              brca2_mutation?
              process_positive_brca1_2_seq_targeted_tests
            elsif normal_brca1_mlpa_targeted_test?||
              normal_brca2_mlpa_targeted_test?
              process_normal_brca1_2_mlpa_targeted_tests
            elsif positive_mlpa_brca1_targeted_test? ||
             positive_exonvariants_in_set_brca1_targeted_test? ||
              positive_mlpa_brca2_targeted_test? ||
              positive_exonvariants_in_set_brca2_targeted_test?
              process_positive_brca1_2_mlpa_targeted_tests
            elsif failed_brca1_mlpa_targeted_test? ||
              failed_brca2_mlpa_targeted_test?
              process_failed_brca1_2_targeted_tests
            # else binding.pry
            end
            @genotypes
          end

          #####################################################################################
          ################ HERE ARE FULL SCREEN TESTS #########################################
          #####################################################################################
          
          
          def all_fullscreen_option2_relevant_fields_nil?
            @brca1_mlpa_result.nil? && @brca2_mlpa_result.nil? &&
            @brca1_mutation.nil? && @brca2_mutation.nil? &&
            @brca1_seq_result.nil? && @brca2_seq_result.nil?
          end
          
          def double_brca_mlpa_negative?
            return if @brca1_mlpa_result.nil? ||  @brca2_mlpa_result.nil?
            no_brca1_cdna_variant? && no_brca2_cdna_variant? &&
            @brca1_mlpa_result.scan(/no\sdel\/dup/i).size.positive? &&
            @brca2_mlpa_result.scan(/no\sdel\/dup/i).size.positive?
          end

          def all_null_cdna_variants_except_full_screen_test?
            return if @fullscreen_result.nil?

            no_brca1_cdna_variant? && no_brca2_cdna_variant?
            # (@brca1_seq_result.nil? || @brca1_seq_result.downcase == 'normal') && @brca2_seq_result.nil? &&
            # @brca1_mutation.nil? && @brca2_mutation.nil? &&
            # @fullscreen_result.scan(CDNA_REGEX).size.positive?
          end

          def no_brca1_cdna_variant?
            (@brca1_seq_result.nil? ||
            @brca1_seq_result.downcase == 'normal' ||
            @brca1_seq_result.scan(CDNA_REGEX).size.zero?) && @brca1_mutation.nil?
          end

          def no_brca2_cdna_variant?
            (@brca2_seq_result.nil? ||
            @brca2_seq_result.downcase == 'normal' ||
            @brca2_seq_result.scan(CDNA_REGEX).size.zero?) && @brca2_mutation.nil?
          end


          def process_fullscreen_result_cdnavariant
            return if @fullscreen_result.nil? ||
            @fullscreen_result.scan(/(?<brca>BRCA1|BRCA2)/i).size.zero?
            positive_gene = @fullscreen_result.match(/(?<brca>BRCA1|BRCA2)/i)[:brca]
            negative_gene = ['BRCA1', 'BRCA2'] - [positive_gene]
            process_positive_cdnavariant(positive_gene, @fullscreen_result.match(CDNA_REGEX)[:cdna], :full_screen)
            process_negative_gene(negative_gene.join, :full_screen)
          end
          

          def brca1_seq_result_missing_cdot?
            return if @brca1_seq_result.nil?
            @brca1_seq_result.scan(/(?<cdna>[0-9]+[a-z]+>[a-z]+)/i).size.positive?
          end

          def brca2_seq_result_missing_cdot?
            return if @brca2_seq_result.nil?
            @brca2_seq_result.scan(/(?<cdna>[0-9]+[a-z]+>[a-z]+)/i).size.positive?
          end
          

          def fullscreen_brca2_mutated_cdna_brca1_normal?
            @ngs_result.scan(/B2|BRCA2|BRCA 2|BR2/i).size.positive? &&
            @ngs_result.scan(CDNA_REGEX).size.positive?
          end
          
          def process_fullscreen_brca2_mutated_cdna_brca1_normal(cdna_variant)
            process_negative_gene('BRCA1', :full_screen)
            process_positive_cdnavariant('BRCA2', cdna_variant, :full_screen)
            @genotypes
          end

          def fullscreen_brca1_mutated_cdna_brca2_normal?
            @ngs_result.scan(/B1|BRCA1|BRCA 1|BR1/i).size.positive? &&
            @ngs_result.scan(CDNA_REGEX).size.positive?
          end

          def process_fullscreen_brca1_mutated_cdna_brca2_normal(cdna_variant)
            process_negative_gene('BRCA2', :full_screen)
            process_positive_cdnavariant('BRCA1', cdna_variant, :full_screen)
            @genotypes
          end

          def fullscreen_brca2_mutated_exon_brca1_normal?
            @ngs_result.scan(/B2|BRCA2|BRCA 2|BR2/i).size.positive? &&
            @ngs_result.scan(EXON_REGEX).size.positive?
          end
    
          def process_fullscreen_brca2_mutated_exon_brca1_normal(exon_variant)
            process_negative_gene('BRCA1', :full_screen)
            exon_variant = @ngs_result.match(EXON_REGEX)
            process_positive_exonvariant('BRCA2', exon_variant, :full_screen)
            @genotypes
          end

          def fullscreen_brca1_mutated_exon_brca2_normal?
            @ngs_result.scan(/B1|BRCA1|BRCA 1|BR1/i).size.positive? &&
            @ngs_result.scan(EXON_REGEX).size.positive?
          end

          def process_fullscreen_brca1_mutated_exon_brca2_normal(exon_variant)
            process_negative_gene('BRCA2', :full_screen)
            exon_variant = @ngs_result.match(EXON_REGEX)
            process_positive_exonvariant('BRCA1', exon_variant, :full_screen)
            @genotypes
          end

          def fullscreen_non_brca_mutated_cdna_gene?
            return if @ngs_result.nil?
            @ngs_result.scan(/(?<nonbrca>CHEK2|PALB2|TP53)/i).size.positive? &&
            @ngs_result.scan(CDNA_REGEX).size.positive?
          end
        
          def fullscreen_non_brca_mutated_exon_gene?
            return if @ngs_result.nil?
            @ngs_result.scan(/(?<nonbrca>CHEK2|PALB2|TP53)/i).size.positive? &&
            @ngs_result.scan(EXON_REGEX).size.positive?
          end

          def process_fullscreen_non_brca_mutated_cdna_gene
            return if @ngs_result.nil?
            process_double_brca_negative(:full_screen)
            positive_gene = @ngs_result.match(/(?<nonbrca>CHEK2|PALB2|TP53)/i)[:nonbrca]
            process_positive_cdnavariant(positive_gene, @ngs_result.match(CDNA_REGEX)[:cdna], :full_screen)
            @genotypes
          end
    
          def process_fullscreen_non_brca_mutated_exon_gene
            return if @ngs_result.nil?
            process_double_brca_negative(:full_screen)
            positive_gene = @ngs_result.match(/(?<nonbrca>CHEK2|PALB2|TP53)/i)[:nonbrca]
            process_positive_exonvariant(positive_gene, @ngs_result.match(EXON_REGEX), :full_screen)
            @genotypes
          end

          def full_screen_test_option1?
            @ngs_result.present? ||
            @ngs_report_date.present?
          end

          def full_screen_test_option2?
            @fullscreen_result.present? || @authoriseddate.present?
          end

          def full_screen_test_option3?
            @predictive_report_date.nil? && @predictive.downcase == 'false' &&
            @aj_assay_result.nil? && @polish_assay_result.nil? &&
            @ngs_result.nil? && @fullscreen_result.nil? && @authoriseddate.nil?
          end

          def process_fullscreen_test_option1
            return if @ngs_result.nil?
            if @ngs_result.downcase.scan(/no\s*mut|no\s*var/i).size.positive?
              process_double_brca_negative(:full_screen)
            elsif @ngs_result.downcase.scan(/fail/i).size.positive?
              process_double_brca_fail(:full_screen)
            elsif fullscreen_brca2_mutated_cdna_brca1_normal?
              process_fullscreen_brca2_mutated_cdna_brca1_normal(@ngs_result.match(CDNA_REGEX)[:cdna])
            elsif fullscreen_brca1_mutated_cdna_brca2_normal?
              process_fullscreen_brca1_mutated_cdna_brca2_normal(@ngs_result.match(CDNA_REGEX)[:cdna])
            elsif fullscreen_brca2_mutated_exon_brca1_normal?
              process_fullscreen_brca2_mutated_exon_brca1_normal(@ngs_result.match(EXON_REGEX))
            elsif fullscreen_brca1_mutated_exon_brca2_normal?
              process_fullscreen_brca1_mutated_exon_brca2_normal(@ngs_result.match(EXON_REGEX))
            elsif fullscreen_non_brca_mutated_cdna_gene?
              process_fullscreen_non_brca_mutated_cdna_gene
            elsif fullscreen_non_brca_mutated_exon_gene?
              process_fullscreen_non_brca_mutated_exon_gene
            end
          end
        
          def process_fullscreen_test_option2
            if @fullscreen_result.present? && @fullscreen_result.downcase.scan(/no\s*mut|no\s*var/i).size.positive?
              process_double_brca_negative(:full_screen)
            elsif fullscreen_non_brca_mutated_cdna_gene?
              process_fullscreen_non_brca_mutated_cdna_gene
            elsif brca2_cdna_variant_fullscreen_option2?
              process_fullscreen_brca2_mutated_cdna_option2
            elsif brca1_cdna_variant_fullscreen_option2?
              process_fullscreen_brca1_mutated_cdna_option2
            elsif all_null_cdna_variants_except_full_screen_test?
              process_fullscreen_result_cdnavariant
            elsif brca2_seq_result_missing_cdot?
              process_missing_cdot_cdna_varint_brca12_seq
            elsif fullscreen_brca1_mlpa_positive_variant?
              process_full_screen_brca1_mlpa_positive_variant(@brca1_mlpa_result.scan(EXON_REGEX))
            elsif fullscreen_brca2_mlpa_positive_variant?
              process_full_screen_brca2_mlpa_positive_variant(@brca2_mlpa_result.scan(EXON_REGEX))
            elsif all_fullscreen_option2_relevant_fields_nil?
              process_double_brca_unknown(:full_screen)
            elsif double_brca_mlpa_negative?
              process_double_brca_negative(:full_screen)
            end
          end

          def process_fullscreen_test_option3
           if all_fullscreen_option2_relevant_fields_nil?
             process_double_brca_unknown(:full_screen)
           elsif brca1_malformed_cdna_fullscreen_option3?
             process_brca1_malformed_cdna_fullscreen_option3
           elsif brca2_malformed_cdna_fullscreen_option3?
             process_brca2_malformed_cdna_fullscreen_option3
           elsif brca1_cdna_variant_fullscreen_option3?
             process_brca1_cdna_variant_fullscreen_option3
           elsif brca2_cdna_variant_fullscreen_option3?
             process_brca2_cdna_variant_fullscreen_option3
           elsif double_brca_mlpa_negative?
             process_double_brca_negative(:full_screen)
           elsif fullscreen_brca1_mlpa_positive_variant?
             process_full_screen_brca1_mlpa_positive_variant(@brca1_mlpa_result.scan(EXON_REGEX))
           elsif fullscreen_brca2_mlpa_positive_variant?
             process_full_screen_brca2_mlpa_positive_variant(@brca2_mlpa_result.scan(EXON_REGEX))
           elsif double_brca_malformed_cdna_fullscreen_option3?
             process_double_brca_malformed_cdna_fullscreen_option3
           elsif @brca2_mlpa_result.present? && @brca1_mlpa_result.present? &&
             @brca2_mlpa_result.scan(/fail/i).size.positive? &&
             @brca1_mlpa_result.scan(/fail/i).size.positive? &&
             process_double_brca_fail(:full_screen)
           # else binding.pry
           end
          end

          def brca1_cdna_variant_fullscreen_option3?
            return if @brca1_mutation.nil? && @brca1_seq_result.nil?
            ((@brca1_mutation.present? && @brca1_mutation.scan(CDNA_REGEX).size.positive?) ||
            (@brca1_seq_result.present? && @brca1_seq_result.scan(CDNA_REGEX).size.positive?))
          end
          

          def process_brca1_cdna_variant_fullscreen_option3
            cdna_variant = [@brca1_mutation,@brca1_seq_result].flatten.uniq.join
            if [@brca2_mutation,@brca2_seq_result].flatten.compact.uniq.empty?
              process_fullscreen_brca1_mutated_cdna_brca2_normal(cdna_variant.match(CDNA_REGEX)[:cdna])
            end
            @genotypes
          end

          def brca2_cdna_variant_fullscreen_option3?
            return if @brca2_mutation.nil? && @brca2_seq_result.nil?
            ((@brca2_mutation.present? && @brca2_mutation.scan(CDNA_REGEX).size.positive?) ||
            (@brca2_seq_result.present? && @brca2_seq_result.scan(CDNA_REGEX).size.positive?))
          end
          

          def process_brca2_cdna_variant_fullscreen_option3
            cdna_variant = [@brca2_mutation,@brca2_seq_result].flatten.uniq.join
            if [@brca1_mutation,@brca1_seq_result].flatten.compact.uniq.empty?
              process_fullscreen_brca2_mutated_cdna_brca1_normal(cdna_variant.match(CDNA_REGEX)[:cdna])
            end
            @genotypes
          end

          def brca1_malformed_cdna_fullscreen_option3?
            ((@brca1_mutation.present? && @brca1_mutation.scan(CDNA_REGEX).size.zero?) ||
            (@brca1_seq_result.present? && @brca1_seq_result.scan(CDNA_REGEX).size.zero?)) &&
            @brca2_mutation.nil? && @brca2_seq_result.nil? &&
            @brca1_mlpa_result.nil? && @brca2_mlpa_result.nil?
          end

          def double_brca_malformed_cdna_fullscreen_option3?
            ((@brca1_mutation.present? && @brca1_mutation.scan(CDNA_REGEX).size.zero?) ||
            (@brca1_seq_result.present? && @brca1_seq_result.scan(CDNA_REGEX).size.zero?)) &&
            ((@brca2_mutation.present? && @brca2_mutation.scan(CDNA_REGEX).size.zero?) ||
            (@brca2_seq_result.present? && @brca2_seq_result.scan(CDNA_REGEX).size.zero?))
          end

          def process_double_brca_malformed_cdna_fullscreen_option3
            if @brca1_seq_result.present?
              cdna_brca1_variant = @brca1_seq_result.scan(/([^\s]+)\s?/i)[0].join
            else cdna_brca1_variant = @brca1_mutation.scan(/([^\s]+)\s?/i)[0].join
            end
            process_positive_cdnavariant('BRCA1', cdna_brca1_variant, :full_screen)
            if @brca2_seq_result.present?
              cdna_brca2_variant = @brca2_seq_result.scan(/([^\s]+)\s?/i)[0].join
            else cdna_brca2_variant = @brca2_mutation.scan(/([^\s]+)\s?/i)[0].join
            end
            process_positive_cdnavariant('BRCA2', cdna_brca2_variant, :full_screen)
          end


          def process_brca1_malformed_cdna_fullscreen_option3
            return if @brca1_seq_result.nil? && @brca1_mutation.nil?
            if @brca1_seq_result.present?
              cdna_variant = @brca1_seq_result.scan(/([^\s]+)/i).join
            else cdna_variant = @brca1_mutation.scan(/([^\s]+)/i).join
            end
            process_fullscreen_brca1_mutated_cdna_brca2_normal(cdna_variant)
            @genotypes
          end

          def brca2_malformed_cdna_fullscreen_option3?
            ((@brca2_mutation.present? && @brca2_mutation.scan(CDNA_REGEX).size.zero?) ||
            (@brca2_seq_result.present? && @brca2_seq_result.scan(CDNA_REGEX).size.zero?)) &&
            @brca1_mutation.nil? && @brca1_seq_result.nil? &&
            @brca1_mlpa_result.nil? && @brca2_mlpa_result.nil?
          end
            
          def process_brca2_malformed_cdna_fullscreen_option3
            return if @brca2_seq_result.nil? && @brca2_mutation.nil?
            if @brca2_seq_result.present?
              cdna_variant = @brca2_seq_result.scan(/([^\s]+)/i)[0].join
            else cdna_variant = @brca2_mutation.scan(/([^\s]+)/i)[0].join
            end
            process_fullscreen_brca2_mutated_cdna_brca1_normal(cdna_variant)
            @genotypes
          end


          def fullscreen_brca1_mlpa_positive_variant?
            return if @brca1_mlpa_result.nil?
            @brca1_mlpa_result.scan(EXON_REGEX).size.positive?
          end

          def process_full_screen_brca1_mlpa_positive_variant(exon_variant)
            process_negative_gene('BRCA2', :full_screen)
            process_positive_exonvariant('BRCA1',exon_variant, :full_screen)
            @genotypes
          end

          def fullscreen_brca2_mlpa_positive_variant?
            return if @brca2_mlpa_result.nil?
            @brca2_mlpa_result.scan(EXON_REGEX).size.positive?
          end

          def process_full_screen_brca2_mlpa_positive_variant(exon_variant)
            process_negative_gene('BRCA1', :full_screen)
            process_positive_exonvariant('BRCA2', exon_variant, :full_screen)
            @genotypes
          end


          def process_missing_cdot_cdna_varint_brca12_seq
            process_positive_cdnavariant('BRCA2', @brca2_seq_result.match(/(?<cdna>[0-9]+[a-z]+>[a-z]+)/i)[:cdna], :full_screen)
            process_negative_gene('BRCA1', :full_screen)
          end
          

          def fullscreen_normal_double_brca_mlpa_option2?
            return if @brca1_mlpa_result.nil? && @brca2_mlpa_result.nil?
            @brca1_mlpa_result.scan(/no del\/dup/i).size.positive? &&
            @brca1_mlpa_result.scan(/no del\/dup/i).size.positive?
          end


          def brca2_cdna_variant_fullscreen_option2?
            (!@brca2_mutation.nil? && @brca2_mutation.scan(CDNA_REGEX).size.positive?) ||
            (!@brca2_seq_result.nil? && @brca2_seq_result.scan(CDNA_REGEX).size.positive?)
          end

          def process_fullscreen_brca2_mutated_cdna_option2
            process_negative_gene('BRCA1', :full_screen)
            if !@brca2_mutation.nil? && @brca2_mutation.scan(CDNA_REGEX).size.positive?
              process_positive_cdnavariant('BRCA2', @brca2_mutation.match(CDNA_REGEX)[:cdna], :full_screen)
            elsif !@brca2_seq_result.nil? && @brca2_seq_result.scan(CDNA_REGEX).size.positive?
              process_positive_cdnavariant('BRCA2', @brca2_seq_result.match(CDNA_REGEX)[:cdna], :full_screen)
            end
            @genotypes
          end

          def brca1_cdna_variant_fullscreen_option2?
            (!@brca1_mutation.nil? && @brca1_mutation.scan(CDNA_REGEX).size.positive?) ||
            (!@brca1_seq_result.nil? && @brca1_seq_result.scan(CDNA_REGEX).size.positive?)
          end

          def process_fullscreen_brca1_mutated_cdna_option2
            process_negative_gene('BRCA2', :full_screen)
            if !@brca1_mutation.nil? && @brca1_mutation.scan(CDNA_REGEX).size.positive?
              process_positive_cdnavariant('BRCA1', @brca1_mutation.match(CDNA_REGEX)[:cdna], :full_screen)
            elsif !@brca1_seq_result.nil? && @brca1_seq_result.scan(CDNA_REGEX).size.positive?
              process_positive_cdnavariant('BRCA1', @brca1_seq_result.match(CDNA_REGEX)[:cdna], :full_screen)
            end
            @genotypes
          end
        end
      end
    end
  end
end
