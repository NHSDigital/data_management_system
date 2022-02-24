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
            @brca1_mlpa_result = record.raw_fields['brca1 mlpa results']
            @brca2_mlpa_result = record.raw_fields['brca2 mlpa results']
            @brca1_seq_result = record.raw_fields['brca1 seq result']
            @brca2_seq_result = record.raw_fields['brca2 seq result']
            
            mtype = record.raw_fields['moleculartestingtype']
            genotype.add_molecular_testing_type_strict(mtype) if mtype
            add_organisationcode_testresult(genotype)
            res = process_tests
            res.each { |cur_genotype| @persister.integrate_and_store(cur_genotype) } unless res.nil?
          end

          def add_organisationcode_testresult(genotype)
            genotype.attribute_map['organisationcode_testresult'] = '699L0'
          end

          def process_tests
            if ashkenazi_test?
              process_ashkenazi_test
            elsif polish_test?
              process_polish_test
            elsif targeted_test_first_option?
              process_targeted_test_first_option
            end
          end

          def process_polish_test
            return if @polish_assay_result.nil?

            if normal_polish_test?
               process_negative_gene('BRCA1', :polish_screen)
            elsif @polish_assay_result.scan(CDNA_REGEX).size.positive?
              process_positive_cdnavariant('BRCA1',@polish_assay_result.match(CDNA_REGEX)[:cdna], :polish_screen)
            end
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
            elsif brca1_mutation_exception? || @aj_assay_result == "68_69delAG"
              if @aj_assay_result == "68_69delAG"
                process_positive_cdnavariant('BRCA1','68_69delAG', :aj_screen)
                process_negative_gene('BRCA2', :aj_screen)
              else
                process_positive_cdnavariant('BRCA1',@aj_assay_result.match(CDNA_REGEX)[:cdna], :aj_screen)
                process_negative_gene('BRCA2', :aj_screen)
              end
            elsif brca2_mutation_exception?
               process_positive_cdnavariant('BRCA2',@aj_assay_result.match(CDNA_REGEX)[:cdna], :aj_screen) 
               process_negative_gene('BRCA1', :aj_screen)
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
          end

          def process_positive_cdnavariant(positive_gene, cdna_variant, test_scope)
            positive_genotype = @genotype.dup
            positive_genotype.add_gene(positive_gene)
            positive_genotype.add_gene_location(cdna_variant)
            positive_genotype.add_status(2)
            positive_genotype.add_test_scope(test_scope)
            @genotypes.append(positive_genotype)
          end

          def process_positive_exonvariant(positive_gene, variant_type, exonic_variant, test_scope)
            positive_genotype = @genotype.dup
            positive_genotype.add_gene(positive_gene)
            positive_genotype.add_variant_type(variant_type)
            positive_genotype.add_exon_location(exonic_variant)
            positive_genotype.add_status(2)
            positive_genotype.add_test_scope(test_scope)
            @genotypes.append(positive_genotype)
          end
          
          def process_negative_gene(negative_gene, test_scope)
            negative_genotype = @genotype.dup
            negative_genotype.add_gene(negative_gene)
            negative_genotype.add_status(1)
            negative_genotype.add_test_scope(test_scope)
            @genotypes.append(negative_genotype)
          end

          def brca1_mutation?
            return if @brca1_mutation.nil?
            @brca1_mutation.scan(CDNA_REGEX).size.positive?
          end
          
          def brca2_mutation?
            return if @brca2_mutation.nil?
            @brca2_mutation.scan(CDNA_REGEX).size.positive?
          end
          
          def brca1_mutation_exception?
            # @aj_assay_result == "68_69delAG" ||
            BRCA1_MUTATIONS.include? @aj_assay_result
          end

          def brca2_mutation_exception?
            BRCA2_MUTATIONS.include? @aj_assay_result
          end

          def targeted_test_first_option?
            @predictive_report_date.present? && @aj_assay_result.nil? && @polish_assay_result.nil?
          end

          def process_targeted_test_first_option
            return if all_null_results_targeted_test_first_option?

            if normal_brca1_seq_targeted_test_first_option?
              process_negative_gene('BRCA1', :targeted_mutation)
            elsif normal_brca2_seq_targeted_test_first_option?
              process_negative_gene('BRCA2', :targeted_mutation)
            elsif positive_seq_brca1_targeted_test_first_option?
              process_positive_cdnavariant('BRCA1',@brca1_seq_result.match(CDNA_REGEX)[:cdna], 
                                           :targeted_mutation)
            elsif positive_seq_brca2_targeted_test_first_option?
              process_positive_cdnavariant('BRCA2',@brca2_seq_result.match(CDNA_REGEX)[:cdna], 
                                          :targeted_mutation)
            elsif positive_mlpa_brca1_targeted_test_first_option?
              process_positive_exonvariant('BRCA1', @brca1_mlpa_result.match(EXON_REGEX)[:deldup], 
                                           @brca1_mlpa_result.match(EXON_REGEX)[:exons], :targeted_mutation)
            elsif positive_mlpa_brca2_targeted_test_first_option?
              process_positive_exonvariant('BRCA2', @brca2_mlpa_result.match(EXON_REGEX)[:deldup], 
                                          @brca2_mlpa_result.match(EXON_REGEX)[:exons], :targeted_mutation)
            else binding.pry
            end
          end

          def normal_brca1_seq_targeted_test_first_option?
            return if @brca1_seq_result.nil?
            @brca1_seq_result.downcase == '-ve' ||
            @brca1_seq_result.downcase == 'neg' ||
            @brca1_seq_result.downcase == 'nrg' ||
            @brca1_seq_result.scan(/neg|nrg|norm/i).size.positive?
          end

          def normal_brca2_seq_targeted_test_first_option?
            return if @brca2_seq_result.nil?
            @brca2_seq_result.downcase == '-ve' ||
            @brca2_seq_result.downcase == 'neg' ||
            @brca2_seq_result.downcase == 'nrg' ||
            @brca2_seq_result.scan(/neg|nrg|norm/i).size.positive?
          end

          def normal_brca2_mlpq_targeted_test_first_option?
            return if @brca2_mlpa_result.nil? || brca1_mlpa_result == "N/A"
            @brca2_seq_result.downcase == 'no del/dup' 
          end

          def positive_seq_brca1_targeted_test_first_option?
            return if @brca1_seq_result.nil?
            @brca1_seq_result.scan(CDNA_REGEX).size.positive?
          end

          def positive_seq_brca2_targeted_test_first_option?
            return if @brca2_seq_result.nil?
            @brca2_seq_result.scan(CDNA_REGEX).size.positive?
          end

          def positive_mlpa_brca1_targeted_test_first_option?
            return if @brca1_mlpa_result.nil?
            @authoriseddate.nil? && @brca1_mlpa_result.scan(EXON_REGEX).size.positive?
          end

          def positive_mlpa_brca2_targeted_test_first_option?
            return if @brca2_mlpa_result.nil?
            @authoriseddate.nil? && @brca2_mlpa_result.scan(EXON_REGEX).size.positive?
          end

          def all_null_results_targeted_test_first_option?
            @brca1_seq_result.nil? && @brca2_seq_result.nil? &&
            @brca1_mpa_result.nil? && @brca2_mlpa_result.nil?
          end

          def ashkenazi_test?
            @ajreport_date.present? || @aj_assay_result.present?
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

        end
      end
    end
  end
end
