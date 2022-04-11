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
            @date_2_3_reported = record.raw_fields['date 2/3 reported']
            @brca1_report_date = record.raw_fields['full brca1 report date']
            @brca2_report_date = record.raw_fields['full brca2 report date']
            @brca2_ptt_report_date = record.raw_fields['brca2 ptt report date']
            @full_ppt_report_date = record.raw_fields['full ptt report date']
            
              
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
          ################ OPTION METHODS ##################################################
          #####################################################################################

          def ashkenazi_test?
            @aj_report_date.present? || @aj_assay_result.present?
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

          #####################################################################################
          ################ PROCESSOR METHODS ##################################################
          #####################################################################################

          def process_ashkenazi_test
            return if @aj_assay_result.nil?
            
            add_ajscreen_date

            if normal_ashkkenazi_test?
               process_double_brca_negative(:aj_screen)
            elsif brca1_mutation? || brca2_mutation?
              if brca1_mutation? & !brca2_mutation?
                process_positive_cdnavariant('BRCA1',@brca1_mutation, :aj_screen)
                process_negative_gene('BRCA2', :aj_screen)
              elsif brca2_mutation? & !brca1_mutation?
                process_positive_cdnavariant('BRCA2',@brca2_mutation, :aj_screen)
                process_negative_gene('BRCA1', :aj_screen)
              elsif brca2_mutation? & brca1_mutation?
                process_positive_cdnavariant('BRCA2',@brca2_mutation, :aj_screen)
                process_positive_cdnavariant('BRCA1',@brca1_mutation, :aj_screen)
              end
              @genotypes
            elsif brca1_mutation_exception? || @aj_assay_result == "68_69delAG"
              if @aj_assay_result == "68_69delAG"
                process_positive_cdnavariant('BRCA1','68_69delAG', :aj_screen)
                process_negative_gene('BRCA2', :aj_screen)
              else
                process_positive_cdnavariant('BRCA1',@aj_assay_result, :aj_screen)
                process_negative_gene('BRCA2', :aj_screen)
              end
              @genotypes
            elsif brca2_mutation_exception?
               process_positive_cdnavariant('BRCA2',@aj_assay_result, :aj_screen) 
               process_negative_gene('BRCA1', :aj_screen)
            end
            @genotypes
          end

          def process_polish_test
            return if @polish_assay_result.nil?

            add_polish_screen_date
            if normal_polish_test?
               process_negative_gene('BRCA1', :polish_screen)
            elsif @polish_assay_result.scan(CDNA_REGEX).size.positive?
              process_positive_cdnavariant('BRCA1',@polish_assay_result, :polish_screen)
            end
            @genotypes
          end

          def process_targeted_test
            add_targeted_screen_date

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
            elsif brca1_malformed_cdna_fullscreen_option3?
              process_brca1_malformed_cdna_targeted_test
            elsif brca2_malformed_cdna_fullscreen_option3?
              process_brca2_malformed_cdna_targeted_test
            elsif no_cdna_variant?
              process_all_null_results_targeted_test(:targeted_mutation)
            end
            @genotypes
          end

          def process_multiple_variants_ngs_results(variants,genes)
            negative_gene = ['BRCA1', 'BRCA2'] - genes
            process_negative_gene(negative_gene.join, :full_screen)  if negative_gene.present?
            # binding.pry
            if genes.uniq.size == variants.uniq.size
              genes.zip(variants).each { |gene,variant| 
              positive_genotype =  @genotype.dup
              positive_genotype.add_gene(gene)
              positive_genotype.add_gene_location(variant) 
              positive_genotype.add_status(2)
              positive_genotype.add_test_scope(:full_screen)
              @genotypes.append(positive_genotype)
              }
            else
              genes = genes.uniq * variants.uniq.size
              genes.zip(variants.uniq).each { |gene,variant| 
              positive_genotype =  @genotype.dup
              positive_genotype.add_gene(gene)
              positive_genotype.add_gene_location(variant) 
              positive_genotype.add_status(2)
              positive_genotype.add_test_scope(:full_screen)
              @genotypes.append(positive_genotype)
              }
            end
            @genotypes
          end
          
          def process_fullscreen_test_option1
            return if @ngs_result.nil?
            add_full_screen_date_option1
            if @ngs_result.downcase.scan(/no\s*mut|no\s*var/i).size.positive?
              process_double_brca_negative(:full_screen)
            elsif @ngs_result.downcase.scan(/fail/i).size.positive?
              process_double_brca_fail(:full_screen)
            elsif @ngs_result.scan(/b(?<brca>1|2)/i).size.positive?
              
            variants = @ngs_result.scan(CDNA_REGEX).uniq.flatten.compact
            tested_genes = @ngs_result.scan(DEPRECATED_BRCA_NAMES_REGEX).flatten.uniq.flatten.compact
            positive_genes = tested_genes.map {|tested_gene|  DEPRECATED_BRCA_NAMES_MAP[tested_gene]}
            process_multiple_variants_ngs_results(variants,positive_genes)
            #   process_multiple_variants_ngs_results(variants,positive_genes)
            elsif @ngs_result.scan(CDNA_REGEX).size > 1
              variants = @ngs_result.scan(CDNA_REGEX).uniq.flatten.compact
              genes = @ngs_result.scan(BRCA_GENES_REGEX).uniq.flatten.compact
              process_multiple_variants_ngs_results(variants,genes)
            elsif fullscreen_brca2_mutated_cdna_brca1_normal?
              process_fullscreen_brca2_mutated_cdna_brca1_normal(@ngs_result)
            elsif fullscreen_brca1_mutated_cdna_brca2_normal?
              process_fullscreen_brca1_mutated_cdna_brca2_normal(@ngs_result)
            elsif fullscreen_brca2_mutated_exon_brca1_normal?
              process_fullscreen_brca2_mutated_exon_brca1_normal(@ngs_result.match(EXON_REGEX))
            elsif fullscreen_brca1_mutated_exon_brca2_normal?
              process_fullscreen_brca1_mutated_exon_brca2_normal(@ngs_result.match(EXON_REGEX))
            elsif fullscreen_non_brca_mutated_cdna_gene?
              process_fullscreen_non_brca_mutated_cdna_gene
            elsif fullscreen_non_brca_mutated_exon_gene?
              process_fullscreen_non_brca_mutated_exon_gene
            elsif @ngs_result.scan(BRCA_GENES_REGEX).size.positive? &&
              @ngs_result.scan(/(?<cdna>[0-9]+[a-z]+>[a-z]+)/i).size.positive?
              positive_genotype = @genotype.dup
              positive_gene = @ngs_result.scan(BRCA_GENES_REGEX).flatten.compact.join
              negative_gene = ["BRCA2", "BRCA1"] - @ngs_result.scan(BRCA_GENES_REGEX).flatten.compact
              process_negative_gene(negative_gene.join, :full_screen)
              positive_genotype.add_gene(positive_gene)
              positive_genotype.add_gene_location(@ngs_result.match(/(?<cdna>[0-9]+[a-z]+>[a-z]+)/i)[:cdna].tr(';',''))
              positive_genotype.add_status(2)
              positive_genotype.add_test_scope(:full_screen)
              @genotypes.append(positive_genotype)
            end
          end

          def process_fullscreen_test_option2
            
            add_full_screen_date_option2
            if @fullscreen_result.present? && @fullscreen_result.downcase.scan(/no\s*mut|no\s*var/i).size.positive?
              process_double_brca_negative(:full_screen)
            elsif fullscreen_non_brca_mutated_cdna_gene?
              process_fullscreen_non_brca_mutated_cdna_gene
            elsif brca1_mutation? && brca2_mutation?
              process_positive_cdnavariant('BRCA1', @brca1_mutation, :full_screen)
              process_positive_cdnavariant('BRCA2', @brca2_mutation, :full_screen)
            elsif brca2_cdna_variant_fullscreen_option2?
              process_fullscreen_brca2_mutated_cdna_option2
            elsif brca1_cdna_variant_fullscreen_option2?
              process_fullscreen_brca1_mutated_cdna_option2
            elsif all_null_cdna_variants_except_full_screen_test?
              process_fullscreen_result_cdnavariant
            elsif fullscreen_brca1_mlpa_positive_variant?
              process_full_screen_brca1_mlpa_positive_variant(@brca1_mlpa_result.scan(EXON_REGEX))
            elsif fullscreen_brca2_mlpa_positive_variant?
              process_full_screen_brca2_mlpa_positive_variant(@brca2_mlpa_result.scan(EXON_REGEX))
            elsif all_fullscreen_option2_relevant_fields_nil?
              process_double_brca_unknown(:full_screen)
            elsif double_brca_mlpa_negative?
              process_double_brca_negative(:full_screen)
            elsif brca1_mlpa_normal_brca2_null?
              process_double_brca_fail(:full_screen)
            else binding.pry
            end
          end

          def process_fullscreen_test_option3
            add_full_screen_date_option3
           if all_fullscreen_option2_relevant_fields_nil?
             process_double_brca_unknown(:full_screen)
           elsif brca1_normal_brca2_nil? || brca2_normal_brca1_nil?
             process_double_brca_negative(:full_screen)
           elsif brca_false_positives?
             process_double_brca_negative(:full_screen)
           elsif normal_brca2_malformed_fullscreen_option3?
             process_double_brca_negative(:full_screen)
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
           elsif brca1_mlpa_normal_brca2_null?
             process_double_brca_fail(:full_screen)
           # else binding.pry
           end
          end



          #####################################################################################
          ################ HERE ARE COMMON METHODS ############################################
          #####################################################################################

          def no_cdna_variant?
            @brca1_mutation.nil? && @brca2_mutation.nil? &&
            @brca1_seq_result.nil? && @brca2_seq_result.nil? &&
            @brca1_mlpa_result.downcase == 'n/a' && @brca2_mlpa_result.downcase == 'n/a'
          end

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
            @brca1_seq_result.scan(/neg|nrg|norm|-ve/i).size.positive? ||
            @brca1_seq_result.scan(/no mut/i).size.positive? ||
            @brca1_seq_result.scan(/no var|no fam|not det/i).size.positive? 
          end

          def normal_brca2_seq?
            return if @brca2_seq_result.nil?
            @brca2_seq_result.downcase == '-ve' ||
            @brca2_seq_result.downcase == 'neg' ||
            @brca2_seq_result.downcase == 'nrg' ||
            @brca2_seq_result.scan(/neg|nrg|norm|-ve/i).size.positive?||
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

          def process_positive_cdnavariant(positive_gene, variant_field, test_scope)
            positive_genotype = @genotype.dup
            positive_genotype.add_gene(positive_gene)
            # positive_genotype.add_gene_location(cdna_variant)
            add_cdnavariant_from_variantfield(variant_field, positive_genotype)
            add_proteinimpact_from_variantfield(variant_field, positive_genotype)
            positive_genotype.add_status(2)
            positive_genotype.add_test_scope(test_scope)
            @genotypes.append(positive_genotype)
          end

          def add_cdnavariant_from_variantfield(variant_field, positive_genotype)
            Maybe(variant_field.match(CDNA_REGEX)[:cdna]).map { |x| positive_genotype.add_gene_location(x.tr(';','')) }
          rescue StandardError
            @logger.debug 'Cannot add cdna variant'
          end

          def add_proteinimpact_from_variantfield(variant_field, positive_genotype)
            Maybe(variant_field.match(PROTEIN_REGEX)[:impact]).map { |x| positive_genotype.add_protein_impact(x) }
          rescue StandardError
            @logger.debug 'Cannot add protein impact'
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
          
          def add_ajscreen_date
            return if @aj_report_date.nil? && @report_report_date.nil?
            if @aj_report_date.present?
              @genotype.attribute_map['authoriseddate'] = @aj_report_date
            elsif @report_report_date.present?
              @genotype.attribute_map['authoriseddate'] = @predictive_report_date
            end
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
          def add_polish_screen_date
            return if @polish_report_date.nil?

              @genotype.attribute_map['authoriseddate'] = @polish_report_date
          end
          
          
          
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

          
          #####################################################################################
          ################ HERE ARE TARGETED TESTS ############################################
          #####################################################################################
          def add_targeted_screen_date
            return if @predictive_report_date.nil?

              @genotype.attribute_map['authoriseddate'] = @predictive_report_date
          end
          


          def positive_mlpa_brca1_targeted_test?
            return if @brca1_mlpa_result.nil?
            (@authoriseddate.nil? || @record.raw_fields['servicereportidentifier'] == '06/03030') &&
            @brca1_mlpa_result.scan(EXON_REGEX).size.positive?
          end

          def positive_mlpa_brca2_targeted_test?
            return if @brca2_mlpa_result.nil?
            (@authoriseddate.nil? || @record.raw_fields['servicereportidentifier'] == '06/03030') &&
            @brca2_mlpa_result.scan(EXON_REGEX).size.positive?
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
              process_positive_cdnavariant('BRCA1',@brca1_seq_result, 
                                         :targeted_mutation)
            elsif brca1_mutation?
              process_positive_cdnavariant('BRCA1',@brca1_mutation, 
                                            :targeted_mutation)
            elsif positive_seq_brca2?
              process_positive_cdnavariant('BRCA2',@brca2_seq_result, 
                                        :targeted_mutation)
            elsif brca2_mutation?
              process_positive_cdnavariant('BRCA2',@brca2_mutation, 
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
          
          def process_brca1_malformed_cdna_targeted_test
            return if @brca1_seq_result.nil? && @brca1_mutation.nil?
            if @brca1_seq_result.present?
              badformat_cdna_brca1_variant = @brca1_seq_result.scan(/([^\s]+)/i)[0].join
            else badformat_cdna_brca1_variant = @brca1_mutation.scan(/([^\s]+)/i)[0].join
            end
            positive_genotype = @genotype.dup
            positive_genotype.add_gene('BRCA1')
            positive_genotype.add_gene_location(badformat_cdna_brca1_variant.tr(';',''))
            positive_genotype.add_status(2)
            positive_genotype.add_test_scope(:targeted_mutation)
            @genotypes.append(positive_genotype)
          end

          def process_brca2_malformed_cdna_targeted_test
            return if @brca2_seq_result.nil? && @brca2_mutation.nil?
            if @brca2_seq_result.present?
              badformat_cdna_brca2_variant = @brca2_seq_result.scan(/([^\s]+)/i)[0].join
            else badformat_cdna_brca2_variant = @brca2_mutation.scan(/([^\s]+)/i)[0].join
            end
            positive_genotype = @genotype.dup
            positive_genotype.add_gene('BRCA2')
            positive_genotype.add_gene_location(badformat_cdna_brca2_variant.tr(';',''))
            positive_genotype.add_status(2)
            positive_genotype.add_test_scope(:targeted_mutation)
            @genotypes.append(positive_genotype)
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
            process_positive_cdnavariant(positive_gene, @fullscreen_result, :full_screen)
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
            (@ngs_result.scan(/B2|BRCA2|BRCA 2|BR2/i).size.positive? &&
            @ngs_result.scan(EXON_REGEX).size.positive?) ||
            (@brca2_mlpa_result.present? && @brca2_mlpa_result.scan(EXON_REGEX).size.positive?)
            
          end
    
          def process_fullscreen_brca2_mutated_exon_brca1_normal(exon_variant)
            process_negative_gene('BRCA1', :full_screen)
            exon_variant = @ngs_result.match(EXON_REGEX)
            process_positive_exonvariant('BRCA2', exon_variant, :full_screen)
            @genotypes
          end

          def fullscreen_brca1_mutated_exon_brca2_normal?
            (@ngs_result.scan(/B1|BRCA1|BRCA 1|BR1/i).size.positive? &&
            @ngs_result.scan(EXON_REGEX).size.positive?) ||
            (@brca1_mlpa_result.present? && @brca1_mlpa_result.scan(EXON_REGEX).size.positive?)
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
            process_positive_cdnavariant(positive_gene, @ngs_result, :full_screen)
            @genotypes
          end
    
          def process_fullscreen_non_brca_mutated_exon_gene
            return if @ngs_result.nil?
            process_double_brca_negative(:full_screen)
            positive_gene = @ngs_result.match(/(?<nonbrca>CHEK2|PALB2|TP53)/i)[:nonbrca]
            process_positive_exonvariant(positive_gene, @ngs_result.match(EXON_REGEX), :full_screen)
            @genotypes
          end

          def add_full_screen_date_option1
            return if @ngs_report_date.nil?

            @genotype.attribute_map['authoriseddate'] = @ngs_report_date
          end





          def add_full_screen_date_option2
            return if @authoriseddate.nil?

            @genotype.attribute_map['authoriseddate'] = @authoriseddate
          end

          def add_full_screen_date_option3
            return if @date_2_3_reported.nil? && @brca1_report_date.nil? && @brca2_report_date.nil? &&
            @brca2_ptt_report_dated.nil? && @full_ppt_report_date.nil?

            date = [
                    @date_2_3_reported, @brca1_report_date, @brca2_report_date, 
                    @brca2_ptt_report_dated, @full_ppt_report_date 
                  ].compact
            if date.size > 1
              @genotype.attribute_map['authoriseddate'] = date.min
            else 
              @genotype.attribute_map['authoriseddate'] = date.join
            end
          end
              



          def brca_false_positives?
            return if @brca1_seq_result.nil? && @brca2_seq_result.nil?
            (@brca1_seq_result.present? && @brca1_seq_result.scan(/-ve/i).size.positive?) ||
            (@brca2_seq_result.present? && @brca2_seq_result.scan(/-ve/i).size.positive?)
          end

          def brca1_cdna_variant_fullscreen_option3?
            return if @brca1_mutation.nil? && @brca1_seq_result.nil?
            ((@brca1_mutation.present? && @brca1_mutation.scan(CDNA_REGEX).size.positive?) ||
            (@brca1_seq_result.present? && @brca1_seq_result.scan(CDNA_REGEX).size.positive?))
          end
          

          def process_brca1_cdna_variant_fullscreen_option3
            cdna_variant = [@brca1_mutation,@brca1_seq_result].flatten.uniq.join
            if [@brca2_mutation,@brca2_seq_result].flatten.compact.uniq.empty?
              process_fullscreen_brca1_mutated_cdna_brca2_normal(cdna_variant)
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
              process_fullscreen_brca2_mutated_cdna_brca1_normal(cdna_variant)
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
              badformat_cdna_brca1_variant = @brca1_seq_result.scan(/([^\s]+)\s?/i)[0].join
            else badformat_cdna_brca1_variant = @brca1_mutation.scan(/([^\s]+)\s?/i)[0].join
            end
            positive_genotype = @genotype.dup
            positive_genotype.add_gene('BRCA1')
            positive_genotype.add_gene_location(badformat_cdna_brca1_variant.tr(';',''))
            positive_genotype.add_status(2)
            positive_genotype.add_test_scope(:full_screen)
            @genotypes.append(positive_genotype)
            if @brca2_seq_result.present?
              badformat_cdna_brca2_variant = @brca2_seq_result.scan(/([^\s]+)\s?/i)[0].join
            else badformat_cdna_brca2_variant = @brca2_mutation.scan(/([^\s]+)\s?/i)[0].join
            end
            positive_genotype = @genotype.dup
            positive_genotype.add_gene('BRCA2')
            positive_genotype.add_gene_location(badformat_cdna_brca2_variant.tr(';',''))
            positive_genotype.add_status(2)
            positive_genotype.add_test_scope(:full_screen)
            @genotypes.append(positive_genotype)
          end


          def process_brca1_malformed_cdna_fullscreen_option3
            process_negative_gene('BRCA2', :full_screen)
            return if @brca1_seq_result.nil? && @brca1_mutation.nil?
            if @brca1_seq_result.present?
              badformat_cdna_brca1_variant = @brca1_seq_result.scan(/([^\s]+)/i)[0].join
            else badformat_cdna_brca1_variant = @brca1_mutation.scan(/([^\s]+)/i)[0].join
            end
            positive_genotype = @genotype.dup
            positive_genotype.add_gene('BRCA1')
            positive_genotype.add_gene_location(badformat_cdna_brca1_variant.tr(';',''))
            positive_genotype.add_status(2)
            positive_genotype.add_test_scope(:full_screen)
            @genotypes.append(positive_genotype)
          end

          def brca2_malformed_cdna_fullscreen_option3?
            ((@brca2_mutation.present? && @brca2_mutation.scan(CDNA_REGEX).size.zero?) ||
            (@brca2_seq_result.present? && @brca2_seq_result.scan(CDNA_REGEX).size.zero?)) &&
            @brca1_mutation.nil? && @brca1_seq_result.nil? &&
            @brca1_mlpa_result.nil? && @brca2_mlpa_result.nil?
          end
          
          def normal_brca2_malformed_fullscreen_option3?
            return if @brca2_seq_result.nil?
            @brca2_seq_result.scan(/neg|norm/i).size.positive?
          end

          def process_brca2_malformed_cdna_fullscreen_option3
            process_negative_gene('BRCA1', :full_screen)
            return if (@brca2_seq_result.nil? && @brca2_mutation.nil?) ||
            (@brca2_seq_result.present? && @brca2_seq_result.scan(/neg|norm/i).size.positive?)
            
            if @brca2_seq_result.present? && @brca2_seq_result.scan(/neg|norm/i).size.zero?
              badformat_cdna_brca2_variant = @brca2_seq_result.scan(/([^\s]+)/i)[0].join
            else badformat_cdna_brca2_variant = @brca2_mutation.scan(/([^\s]+)/i)[0].join
            end
            positive_genotype = @genotype.dup
            positive_genotype.add_gene('BRCA2')
            positive_genotype.add_gene_location(badformat_cdna_brca2_variant.tr(';',''))
            positive_genotype.add_status(2)
            positive_genotype.add_test_scope(:full_screen)
            @genotypes.append(positive_genotype)
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
              process_positive_cdnavariant('BRCA2', @brca2_mutation, :full_screen)
            elsif !@brca2_seq_result.nil? && @brca2_seq_result.scan(CDNA_REGEX).size.positive?
              process_positive_cdnavariant('BRCA2', @brca2_seq_result, :full_screen)
            end
            @genotypes
          end

          def brca1_cdna_variant_fullscreen_option2?
            (!@brca1_mutation.nil? && @brca1_mutation.scan(CDNA_REGEX).size.positive?) ||
            (!@brca1_seq_result.nil? && @brca1_seq_result.scan(CDNA_REGEX).size.positive?)
          end

          def brca1_normal_brca2_nil?
            (@brca2_mutation.nil? && @brca2_seq_result.nil? && @brca2_mlpa_result.nil?) &&
            ((@brca1_mlpa_result.present? &&
            @brca1_mlpa_result.scan(/no del\/dup/i).size.positive?) ||
            (@brca1_seq_result.present? && @brca1_seq_result.scan(/neg|norm/i).size.positive?))
          end

          def brca2_normal_brca1_nil?
            (@brca1_mutation.nil? && @brca1_seq_result.nil? && @brca1_mlpa_result.nil?) &&
            ((@brca2_mlpa_result.present? &&
            @brca2_mlpa_result.scan(/no del\/dup/i).size.positive?)||
            (@brca2_seq_result.present? && @brca2_seq_result.scan(/neg|norm/i).size.positive?))
          end

          def brca1_mlpa_normal_brca2_null?
            return if @brca2_mlpa_result.nil? && @brca1_mlpa_result.nil?
            (@brca1_mlpa_result.nil? && @brca2_mlpa_result.scan(/no del\/dup/i).size.positive?) ||
            (@brca2_mlpa_result.nil? && @brca1_mlpa_result.scan(/no del\/dup/i).size.positive?) ||
            (@brca2_mlpa_result.downcase == 'n/a' && @brca1_mlpa_result.scan(/no del\/dup/i).size.positive?) ||
            (@brca1_mlpa_result.downcase == 'n/a' && @brca2_mlpa_result.scan(/no del\/dup/i).size.positive?)
          end

          def process_fullscreen_brca1_mutated_cdna_option2
            process_negative_gene('BRCA2', :full_screen)
            if !@brca1_mutation.nil? && @brca1_mutation.scan(CDNA_REGEX).size.positive?
              process_positive_cdnavariant('BRCA1', @brca1_mutation, :full_screen)
            elsif !@brca1_seq_result.nil? && @brca1_seq_result.scan(CDNA_REGEX).size.positive?
              process_positive_cdnavariant('BRCA1', @brca1_seq_result, :full_screen)
            end
            @genotypes
          end
        end
      end
    end
  end
end