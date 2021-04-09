require 'possibly'

module Import
  module Colorectal
    module Providers
      module Salisbury
        # Process Salisbury-specific record details into generalized internal genotype format
        class SalisburyHandlerColorectal < Import::Brca::Core::ProviderHandler
          TEST_SCOPE_MAPPING_COLO = {
            'hnpcc mlpa' => :targeted_mutation,
            'hnpcc predictives' => :targeted_mutation,
            'lynch syndrome 3 gene panel' => :full_screen,
            'lynch syndrome 3 gene panel - re-analysis' => :full_screen
          } .freeze

          TEST_TYPE_MAPPING_COLO = { 'lynch syndrome 3 gene panel' => :diagnostic,
                                     'lynch syndrome 3 gene panel - re-analysis' => :diagnostic,
                                     'hnpcc mlpa' => :predictive,
                                     'hnpcc predictives' => :predictive } .freeze

          PASS_THROUGH_FIELDS_COLO = %w[age consultantcode
                                        servicereportidentifier
                                        providercode
                                        authoriseddate
                                        requesteddate] .freeze

          POSITIVE_TEST = /variant|pathogenic|deletion/i .freeze
          FAILED_TEST = /Fail*+|gaps/i .freeze
          GENE_LOCATION_REGEX = /.*c\.(?<gene>[^ ]+)(?: p\.\((?<protein>.*)\))?.*/i .freeze
          EXON_LOCATION_REGEX = /exons? (\d+[a-z]*(?: ?- ?\d+[a-z]*)?)/i .freeze
          DEL_DUP_REGEX = /(?:\W*(del)(?:etion|[^\W])?)|(?:\W*(dup)(?:lication|[^\W])?)/i .freeze
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

          def initialize(batch)
            super
          end

          def process_fields(record)
            genocolorectal = Import::Colorectal::Core::Genocolorectal.new(record)
            genocolorectal.add_passthrough_fields(record.mapped_fields,
                                                  record.raw_fields,
                                                  PASS_THROUGH_FIELDS_COLO)
            # add_colorectal_from_raw_test(genocolorectal, record) # Added by Francesco
            extract_variant(record.raw_fields['genotype'], genocolorectal)
            Maybe(record.raw_fields['moleculartestingtype']).each do |ttype|
              genocolorectal.add_molecular_testing_type_strict(TEST_TYPE_MAPPING_COLO[ttype.downcase.strip])
              scope = TEST_SCOPE_MAPPING_COLO[ttype.downcase.strip]
              genocolorectal.add_test_scope(scope) if scope
            end
            genocolorectal.add_specimen_type(record.mapped_fields['specimentype'])
            genocolorectal.add_received_date(record.raw_fields['date of receipt'])
            extract_teststatus(genocolorectal, record)
            add_organisationcode_testresult(genocolorectal)
            res = add_colorectal_from_raw_test(genocolorectal, record)
            res.map { |cur_genotype| @persister.integrate_and_store(cur_genotype) }
            status = genocolorectal.attribute_map['teststatus']
            @logger.debug "Extracted Teststatus was #{status}"
          end

          def add_organisationcode_testresult(genocolorectal)
            genocolorectal.attribute_map['organisationcode_testresult'] = '699H0'
          end
          
          def add_colorectal_from_raw_test(genocolorectal, record)
            colo_string = record.raw_fields['test']
            genotypes = []
            if colo_string.scan(COLORECTAL_GENES_REGEX).size > 1
              @logger.error "Multiple genes detected in input string: #{colo_string};"
              colo_string.scan(COLORECTAL_GENES_REGEX).each do |gene|
                genocolorectal1 = genocolorectal.dup_colo
                genocolorectal1.add_gene_colorectal(gene[0])
                genotypes << genocolorectal1
              end
            elsif COLORECTAL_GENES_REGEX.match(colo_string) && colo_string.scan(COLORECTAL_GENES_REGEX).size == 1
              genocolorectal.add_gene_colorectal($LAST_MATCH_INFO[:colorectal])
              genotypes << genocolorectal
              @logger.debug "SUCCESSFUL gene change parse for: #{$LAST_MATCH_INFO[:colorectal]}"
            else
              @logger.debug "FAILED cdna channge parse for  #{colo_string}"
            end
            genotypes
          end

          def extract_teststatus(genocolorectal, record)
            case record.raw_fields['status']
            when POSITIVE_TEST
              genocolorectal.add_status(:positive)
              @logger.debug "POSITIVE status for : #{record.raw_fields['status']}"
            when /Normal/
              genocolorectal.add_status(:negative)
              @logger.debug "POSITIVE status for : #{record.raw_fields['status']}"
            when /No mutation detected/
              genocolorectal.add_status(:negative)
              @logger.debug "POSITIVE status for : #{record.raw_fields['status']}"
            when /benign/i
              genocolorectal.add_status(:negative)
              @logger.debug "POSITIVE status for : #{record.raw_fields['status']}"
            when FAILED_TEST
              genocolorectal.add_status(:failed)
              @logger.debug "FAILED status for : #{record.raw_fields['status']}"
            else
              @logger.debug "Cannot determine test status for : #{record.raw_fields['status']}"
            end
          end

          def extract_variant(genotype_string, genocolorectal)
            matches = GENE_LOCATION_REGEX.match(genotype_string)
            exon_matches = EXON_LOCATION_REGEX.match(genotype_string)
            if genotype_string.blank?
              # TODO: what is the desired value to put in here? Negative?
              genocolorectal.set_negative
              return
            end
            if matches
              genocolorectal.add_gene_location(matches[:gene]) if matches[1]
              genocolorectal.add_protein_impact(matches[:protein]) if matches[2]
            elsif exon_matches
              genocolorectal.add_exon_location(exon_matches[1].delete(' '))
              genocolorectal.add_variant_type(genotype_string)
            else
              @logger.warn "Cannot extract gene location from raw test: #{genotype_string}"
            end
          end
        end
      end
    end
  end
end
