require 'possibly'
# require 'import/brca/providers/newcastle/newcastle_storage_manager'

module Import
  module Brca
    module Providers
      module Newcastle
        # Process Newcastle-specific record details into generalized internal genotype format
        class NewcastleHandler < Import::Brca::Core::ProviderHandler
          TEST_SCOPE_MAP = { 'brca-ng'           => :full_screen,
                             'brca-rapid screen' => :full_screen,
                             'brca top up'       => :full_screen,
                             'brca-pred'         => :targeted_mutation,
                             'brca1'             => :targeted_mutation,
                             'brca2'             => :targeted_mutation }.freeze

          TEST_TYPE_MAP = { 'diag - symptoms'    => :diagnostic,
                            'diagnosis'          => :diagnostic,
                            'diagnostic'         => :diagnostic,
                            'diagnostic test'    => :diagnostic,
                            'presymptomatic'     => :predictive,
                            'predictive'         => :predictive,
                            'predictive test'    => :predictive,
                            'carrier'            => :carrier,
                            'carrier test'       => :carrier,
                            'prenatal diagnosis' => :prenatal }.freeze

          TEST_SCOPE_FROM_TYPE_MAP =   {  'carrier' => :targeted_mutation,
                                          'carrier test' => :targeted_mutation,
                                          'diag - symptoms' => :full_screen,
                                          'diagnosis' => :full_screen,
                                          'diagnostic' => :full_screen,
                                          'diagnostic test' => :full_screen,
                                          'diagnostic/forward' => :full_screen,
                                          'family studies' => :targeted_mutation,
                                          'predictive' => :targeted_mutation,
                                          'predictive test' => :targeted_mutation,
                                          'presymptomatic' => :targeted_mutation,
                                          'presymptomatic test' => :targeted_mutation,
                                          'storage' => :full_screen }.freeze

          PASS_THROUGH_FIELDS = %w[age authoriseddate
                                   requesteddate
                                   specimentype
                                   providercode
                                   consultantcode
                                   servicereportidentifier].freeze

          FIELD_NAME_MAPPINGS = { 'consultantcode'    => 'practitionercode',
                                  'ngs sample number' => 'servicereportidentifier' }.freeze

          PROTEIN_REGEX = /p\.\((?<impact>.+)\)|
                          \(p\.(?<impact>[A-Za-z]+.+)\)|
                          p\.(?<impact>[A-Za-z]+.+)/ix.freeze # Added by Francesco
          BRCA1_REGEX = /BRCA1/i.freeze
          BRCA2_REGEX = /BRCA2/i.freeze
          CDNA_REGEX = /c\.(?<cdna>[0-9]+[a-z]+>[a-z]+)(.+)?|
                        c\.(?<cdna>[0-9]+.[0-9]+[a-z]+>[a-z]+)(.+)?|
                        c\.(?<cdna>[0-9]+.[0-9]+[a-z]+)(.+)?/ix.freeze

          def initialize(batch)
            @records_attempted_counter = 0
            @failed_variant_counter    = 0
            @variants_processed_counter = 0
            @ex = Import::ExtractionUtilities::LocationExtractor.new
            super
          end

          def attach_persister(batch)
            @persister = Import::Brca::Providers::Newcastle::NewcastlePersister.new(batch)
          end

          def process_fields(record)
            @records_attempted_counter += 1
            genotype = Import::Brca::Core::GenotypeBrca.new(record)
            genotype.add_passthrough_fields(record.mapped_fields,
                                            record.raw_fields,
                                            PASS_THROUGH_FIELDS,
                                            FIELD_NAME_MAPPINGS)
            investigation_code = record.raw_fields['investigation code']
            genotype.add_gene(investigation_code) unless investigation_code.nil?
            gene = record.raw_fields['gene']
            genotype.add_gene(gene) unless gene.nil?
            identifier = record.raw_fields['ngs sample number']
            genotype.add_servicereportidentifier(identifier) unless identifier.nil?
            process_test_type(genotype, record)
            process_investigation_code(genotype, record)
            process_variant_details(genotype, record)
            add_brca_from_raw_genotype(genotype, record) # Added by Francesco
            add_cdna_change_from_report(genotype, record) # Added by Francesco
            process_protein_impact(genotype, record) # Added by Francesco
            add_organisationcode_testresult(genotype)
            final_results = process_raw_genotype(genotype, record)
            final_results.map { |x| @persister.integrate_and_store(x) }
          end

          def add_organisationcode_testresult(genotype)
            genotype.attribute_map['organisationcode_testresult'] = '699A0'
          end

          def process_investigation_code(genotype, record)
            if record.raw_fields['service category'].to_s.downcase.strip == 'o'
              @logger.info 'Found O'
              add_scope_from_service_category(record.raw_fields['service category'].to_s, genotype)
            elsif TEST_SCOPE_MAP.key?(record.raw_fields['investigation code'].downcase.strip)
              genotype.add_test_scope(TEST_SCOPE_MAP[record.raw_fields['investigation code'].
                                      downcase.strip])
              @logger.info 'ADDED SCOPE FROM SCOPE'
            elsif TEST_SCOPE_FROM_TYPE_MAP.key?(record.raw_fields['moleculartestingtype']&.
                                                downcase.strip)
              genotype.add_test_scope(TEST_SCOPE_FROM_TYPE_MAP[record.raw_fields['moleculartestingtype'].
                                                               downcase.strip])
              @logger.info 'ADDED SCOPE FROM TYPE'
            else
              @logger.info 'NOTHING TO BE DONE'
            end
          end

          def process_variant_details(genotype, record)
            #      Maybe(record.mapped_fields['variantpathclass']).
            #        or_else(Maybe(record.raw_fields['variant type'])).
            #        map { |x| genotype.add_variant_class(x) }
            variantclass = Maybe(record.mapped_fields['variantpathclass']).
                           or_else(Maybe(record.raw_fields['variant type']))
            genotype.add_variant_class(variantclass)
            Maybe(record.raw_fields['variant name']).each do |variant|
              @variants_processed_counter += 1
              @failed_variant_counter += genotype.add_typed_location(@ex.extract_type(variant))
            end
          end

          def process_test_type(genotype, record)
            # cludge to handle their change in field mapping...
            reason = record.raw_fields['referral reason']
            unless reason.nil?
              genotype.add_molecular_testing_type_strict(
                TEST_TYPE_MAP[reason.downcase.strip]
              )
            end
            mtype = record.raw_fields['moleculartestingtype']
            unless mtype.nil?
              genotype.add_molecular_testing_type_strict(
                TEST_TYPE_MAP[mtype.downcase.strip]
              )
            end
          end

          def process_raw_genotype(genotype, record)
            # **************** These are dependant on the format change *****************
            geno = record.raw_fields['teststatus']
            case geno
            when /nmd/
              genotype.add_status(1)
              if genotype.get('gene').nil?
                genotype2 = genotype.dup
                genotype.add_gene(1)
                genotype2.add_gene(2)
                [genotype, genotype2]
              else
                [genotype]
              end
            when /variant/, /abnormal/, /pathogenic/
              genotype.add_status(2)
              [genotype]
            when /het/, /hemi/
              genotype.add_status(2)
              genotype.add_zygosity(geno)
              [genotype]
            when /fail/
              genotype.add_status(9)
              [genotype]
            when /completed/, /no-result/, /other/, /verify/, /low/ # No appropriate status
              [genotype]
            when nil
              [genotype]
            else
              @logger.info "Encountered unfamiliar genotype string: #{geno}"
              [genotype]
            end
          end

          def add_brca_from_raw_genotype(genotype, record)
            case record.raw_fields['gene']
            when BRCA1_REGEX
              genotype.add_gene('BRCA1')
            when BRCA2_REGEX
              genotype.add_gene('BRCA2')
            end
          end

          def add_cdna_change_from_report(genotype, record)
            case record.raw_fields['genotype']
            when CDNA_REGEX
              genotype.add_gene_location($LAST_MATCH_INFO[:cdna])
              @logger.debug "SUCCESSFUL cdna change parse for: #{$LAST_MATCH_INFO[:cdna]}"
            end
          end

          def process_protein_impact(genotype, record)
            case record.raw_fields['genotype']
            when PROTEIN_REGEX
              genotype.add_protein_impact($LAST_MATCH_INFO[:impact])
              @logger.debug "SUCCESSFUL protein change parse for: #{$LAST_MATCH_INFO[:impact]}"
            else
              @logger.debug "FAILED protein change parse for: #{record.raw_fields['genotype']}"
            end
          end

          def add_scope_from_service_category(service_category, genotype)
            return if service_category.blank?

            if service_category.downcase.strip == 'o'
              genotype.add_test_scope(:full_screen)
            else
              @logger.info 'Possibly not a full screen'
            end
          end

          def summarize
            @logger.info ' ************** Handler Summary **************** '
            @logger.info "Num bad variants: #{@failed_variant_counter} of "\
                         "#{@variants_processed_counter} processed"
          end
        end
      end
    end
  end
end
