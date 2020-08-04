require 'possibly'
require 'import/genotype'
require 'import/storage_manager/persister'
require 'core/provider_handler'
require 'core/extraction_utilities'
require 'pry'

module Import
  module Brca
    module Providers
      module Oxford
        # Process Oxford-specific record details into generalized internal genotype format
        class OxfordHandler < Import::Brca::Core::ProviderHandler
          TEST_SCOPE_MAP = { 'brca_multiplicom'           => :full_screen,
                             'breast-tp53 panel'          => :full_screen,
                             'breast-uterine-ovary panel' => :full_screen,
                             'targeted'                   => :targeted_mutation } .freeze

          TEST_METHOD_MAP = { 'Sequencing, Next Generation Panel (NGS)' => :ngs,
                              'Sequencing, Dideoxy / Sanger'            => :sanger } .freeze

          PASS_THROUGH_FIELDS = %w[age consultantcode
                                   servicereportidentifier
                                   providercode
                                   authoriseddate
                                   requesteddate
                                   variantpathclass
                                   sampletype
                                   referencetranscriptid] .freeze
          # TODO: transcript id may still need form normalization

          PROTEIN_REGEX = /p\.\[(?<impact>(.*?))\]|p\..+/i.freeze
          CDNA_REGEX = /c\.\[?(?<cdna>[0-9]+.+[a-z])\]?/i.freeze
          def process_fields(record)
            genotype = Import::Brca::Core::GenotypeBrca.new(record)
            genotype.add_passthrough_fields(record.mapped_fields,
                                            record.raw_fields,
                                            PASS_THROUGH_FIELDS)
            # ********************** Assign gene ************************
            assign_method(genotype, record)
            assign_test_scope(genotype, record)
            assign_test_type(genotype, record)
            process_gene(genotype, record)
            process_cdna_change(genotype, record)
            # assign_cdna_change(genotype, record)
            process_protein_impact(genotype, record)
            # assign_protein_change(genotype, record)
            assign_genomic_change(genotype, record)
            @persister.integrate_and_store(genotype)
          end

          def assign_method(genotype, record)
            # ******************* Assign testing method ************************
            Maybe(record.raw_fields['karyotypingmethod']).each do |raw_method|
              method = TEST_METHOD_MAP[raw_method]
              if method
                genotype.add_method(method)
              else
                @logger.warn "Unknown method: #{raw_method}; possibly need to update map"
              end
            end
          end

          def assign_test_type(genotype, record)
            # ******************* Assign testing type  ************************
            Maybe(record.raw_fields['moleculartestingtype']).each do |ttype|
              if ttype.downcase != 'diagnostic'
                @logger.warn "Oxford provided test type: #{ttype}; expected" \
                             'diagnostic only'
              end
              # TODO: check that 'diagnostic' is exactly how it comes through
              genotype.add_molecular_testing_type_strict(ttype)
            end
          end

          def assign_test_scope(genotype, record)
            # ******************* Assign test scope ************************
            Maybe(record.raw_fields['scope / limitations of test']).each do |ttype|
              scope = TEST_SCOPE_MAP[ttype.downcase.strip]
              genotype.add_test_scope(scope) if scope
            end
          end

          # def assign_cdna_change(genotype, record)
          #   # ******************* Assign c. change ************************
          #   Maybe(record.mapped_fields['codingdnasequencechange']).each do |dna|
          #     change = case dna
          #              when /c\.\[(?<change>[.+])\]\+[=]/
          #                "c.#{$LAST_MATCH_INFO[:change]}"
          #              else
          #                @logger.warn "Could not extract Oxford sequence: #{dna}"
          #              end
          #     genotype.add_gene_location(change)
          #   end
          # end

          def process_cdna_change(genotype, record)
            case record.mapped_fields['codingdnasequencechange']
            when CDNA_REGEX
              genotype.add_gene_location($LAST_MATCH_INFO[:cdna])
              @logger.debug "SUCCESSFUL cdna change parse for: #{$LAST_MATCH_INFO[:cdna]}"
            else
              @logger.debug 'FAILED cdna change parse for: ' \
                            "#{record.raw_fields['codingdnasequencechange']}"
            end
          end

          def process_protein_impact(genotype, record)
            case record.raw_fields['proteinimpact']
            when PROTEIN_REGEX
              genotype.add_protein_impact($LAST_MATCH_INFO[:impact])
              @logger.debug "SUCCESSFUL protein change parse for: #{$LAST_MATCH_INFO[:impact]}"
            else
              @logger.debug 'FAILED protein change parse for: ' \
                            "#{record.raw_fields['proteinimpact']}"
            end
          end

          def process_gene(genotype, record)
            gene = record.mapped_fields['gene'].to_i
            case gene
            when Integer then
              if (7..8).cover? gene
                genotype.add_gene(record.mapped_fields['gene'].to_i)
                # @successful_gene_counter += 1
                @logger.debug 'SUCCESSFUL gene parse for:' \
                               "#{record.mapped_fields['gene'].to_i}"
              else
                @logger.debug 'FAILED gene parse for: ' \
                               "#{record.mapped_fields['gene'].to_i}"
                # @failed_gene_counter += 1
              end
            end
          end

          # def assign_protein_change(genotype, record)
          #   # ******************* Assign p. change ************************
          #   Maybe(record.mapped_fields['proteinimpact']).each do |protein|
          #     change = case protein
          #              when /p\.(?:\(|\[)(?<change>[.+])(?:\)|\])\+[=]/
          #                "p.#{$LAST_MATCH_INFO[:change]}"
          #              else
          #                @logger.warn "Could not extract Oxford impact: #{protein}"
          #              end
          #     genotype.add_protein_impact(change)
          #   end
          # end

          def assign_genomic_change(genotype, record)
            # ******************* Assign genomic change ************************
            Maybe(record.raw_fields['genomicchange']).each do |raw_change|
              case raw_change
              when /Chr(?<chromosome>\d+)\.hg(?<genome_build>\d+):g\.(?<effect>.+)/i
                genotype.add_genome_build($LAST_MATCH_INFO[:genome_build].to_i)
                genotype.add_parsed_genomic_change($LAST_MATCH_INFO[:chromosome],
                                                   $LAST_MATCH_INFO[:effect])
              else
                genotype.add_raw_genomic_change(raw_change)
                @logger.warn "Could not process, so adding raw genomic change: #{raw_change}"
              end
            end
          end
        end
      end
    end
  end
end

