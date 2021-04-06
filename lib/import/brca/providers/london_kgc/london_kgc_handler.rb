require 'possibly'
require 'pry'

module Import
  module Brca
    module Providers
      module LondonKgc
        # London KGC Importer
        class LondonKgcHandler < Import::Brca::Core::ProviderHandler
          PASS_THROUGH_FIELDS = %w[age sex consultantcode collecteddate
                                   receiveddate authoriseddate servicereportidentifier
                                   providercode receiveddate ] .freeze

          BRCA_REGEX = /(?<brca>BRCA(1|2))/i .freeze
          CDNA_REGEX = /c\.(?<cdna>[0-9]+[^\s]+)/i .freeze
          PATHCLASS_REGEX = /(?<pathclass>[1-5]) \-/i .freeze
          EXON_LOCATION_REGEX = /(?<exons> exons? (\d+[a-z]*(?: ?- ?\d+[a-z]*)?))/i .freeze
          PROTEIN_REGEX = /p\.(\()?(?<impact>[a-z]+[0-9]+[a-z]+(\*)?([0-9]+)?)|
                          p\.(\()?(?<impact>[a-z]+[0-9]+\*(\*)?([0-9]+)?)/i
          def initialize(batch)
            super
          end

          def process_fields(record)
            genotype = Import::Brca::Core::GenotypeBrca.new(record)
            genotype.add_passthrough_fields(record.mapped_fields,
                                            record.raw_fields,
                                            PASS_THROUGH_FIELDS)
            #process_cdna_change(genotype, record)
            process_varpathclass(genotype, record)
            process_exons(genotype, record)
            add_organisationcode_testresult(genotype)
            res = process_gene(genotype, record)
            res.map { |cur_genotype| @persister.integrate_and_store(cur_genotype) }
            # @persister.integrate_and_store(genotype)
          end

          def add_organisationcode_testresult(genotype)
            genotype.attribute_map['organisationcode_testresult'] = '697Q0'
          end

          def process_single_cdna_change(genotype, record)
            case record.mapped_fields['genotype']
            when CDNA_REGEX
              genotype.add_gene_location($LAST_MATCH_INFO[:cdna])
              @logger.debug "SUCCESSFUL cdna change parse for: #{$LAST_MATCH_INFO[:cdna]}"
              genotype.add_status(:positive)
            when /No mutation detected/
              @logger.debug 'No mutation detected'
              genotype.add_status(:negative)
            else
              @logger.debug 'Impossible to parse cdna change'
            end
          end

          def process_gene(genotype, record)
            geno = record.mapped_fields['genotype']
            genotypes = []
            if geno.scan(BRCA_REGEX).size == 1
              @logger.debug "SUCCESSFUL gene parse for: #{BRCA_REGEX.match(geno)[:brca]}"
               genotype.add_gene(BRCA_REGEX.match(geno)[:brca])
               if CDNA_REGEX.match(geno)
                 genotype.add_gene_location(CDNA_REGEX.match(geno)[:cdna]) 
                 @logger.debug "SUCCESSFUL cdna change parse for: #{CDNA_REGEX.match(geno)[:cdna]}"
               end
               if PROTEIN_REGEX.match(geno)
                 genotype.add_protein_impact(PROTEIN_REGEX.match(geno)[:impact]) 
                 @logger.debug "SUCCESSFUL protein impact parse for: #{PROTEIN_REGEX.match(geno)[:impact]}"
               end
               genotype.add_status(:positive)
               genotypes.append(genotype)
            elsif geno.scan(BRCA_REGEX).size > 1
              genotype2 = genotype.dup
              genotype.add_gene(geno.scan(BRCA_REGEX).flatten[0])
              genotype2.add_gene(geno.scan(BRCA_REGEX).flatten[1])
              @logger.debug 'SUCCESSFUL cdna change parse for: '\
               "#{geno.scan(BRCA_REGEX).flatten[0]} and #{geno.scan(BRCA_REGEX).flatten[1]}"
              genotype.add_gene_location(geno.scan(CDNA_REGEX).flatten[0])
              genotype2.add_gene_location(geno.scan(CDNA_REGEX).flatten[1])
              genotype.add_protein_impact(geno.scan(PROTEIN_REGEX).flatten[0])
              genotype2.add_protein_impact(geno.scan(PROTEIN_REGEX).flatten[1])
              genotype.add_status(:positive)
              genotype2.add_status(:positive)
              genotypes.append(genotype,genotype2)
            elsif /No mutation detected/.match(geno)
              @logger.debug 'No mutation detected'
              genotype.add_status(:negative)
              genotypes.append(genotype)
            else
              @logger.debug 'Impossible to parse cdna change'
            end
            genotypes
          end

          def process_varpathclass(genotype, record)
            case record.mapped_fields['variantpathclass']
            when PATHCLASS_REGEX
              genotype.add_variant_class($LAST_MATCH_INFO[:pathclass].to_i)
              @logger.debug "SUCCESSFUL variantpathclass parse for: #{$LAST_MATCH_INFO[:pathclass]}"
            end
          end

          def process_exons(genotype, record)
            case record.mapped_fields['genotype']
            when EXON_LOCATION_REGEX
              genotype.add_exon_location($LAST_MATCH_INFO[:exons])
              genotype.add_variant_type(record.mapped_fields['genotype'])
              @logger.debug "SUCCESSFUL exon parse for: #{record.mapped_fields['genotype']}"
            end
          end
        end
      end
    end
  end
end
