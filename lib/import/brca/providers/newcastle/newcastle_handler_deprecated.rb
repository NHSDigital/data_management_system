require 'possibly'
module Import
  module Brca
    module Providers
      module Newcastle
        # Process Newcastle-specific record details into generalized internal genotype format
        class NewcastleHandlerDeprecated < Import::Brca::Core::ProviderHandler
          include Utility
          TEST_SCOPE_MAP = { 'brca-ng'           => :full_screen,
                             'brca-rapid screen' => :full_screen,
                             'brca-pred'         => :targeted_mutation } .freeze
          TEST_TYPE_MAP = { 'diag - symptoms'    => :diagnostic,
                            'diagnosis'          => :diagnostic,
                            'diagnostic'         => :diagnostic,
                            'diagnostic test'    => :diagnostic,
                            'presymptomatic'     => :predictive,
                            'predictive'         => :predictive,
                            'predictive test'    => :predictive,
                            'carrier'            => :carrier,
                            'carrier test'       => :carrier,
                            'prenatal diagnosis' => :prenatal } .freeze
          PASS_THROUGH_FIELDS = %w[age authoriseddate
                                   requesteddate
                                   specimentype
                                   providercode
                                   consultantcode
                                   servicereportidentifier] .freeze
          FIELD_NAME_MAPPINGS = { 'consultantcode'    => 'practitionercode',
                                  'ngs sample number' => 'servicereportidentifier' } .freeze
          def initialize(batch)
            @records_attempted_counter = 0
            @failed_variant_counter    = 0
            @variants_processed_counter = 0
            @ex = LocationExtractor.new
            super
          end

          def attach_persister(batch)
            @persister = NewcastlePersister.new(batch)
          end

          def process_fields(record)
            @records_attempted_counter += 1
            genotype = Import::Brca::Core::Genotype.new(record)
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
            final_results = process_raw_genotype(genotype, record)
            final_results.map { |x| @persister.integrate_and_store(x) }
          end

          def process_investigation_code(genotype, record)
            raw_code = record.raw_fields['investigation code']
            case raw_code
            when String
              scope = TEST_SCOPE_MAP[raw_code.downcase.strip]
              if scope
                genotype.add_test_scope(scope)
              else
                add_scope_from_service_category(record.raw_fields['service category'], genotype)
              end
            when Nil
              add_scope_from_service_category(record.raw_fields['service category'], genotype)
            end
          end

          def process_variant_details(genotype, record)
            Maybe(record.mapped_fields['variantpathclass']).
              or_else(Maybe(record.raw_fields['variant type'])).
              map { |x| genotype.add_variant_class(x) }
            Maybe(record.raw_fields['variant name']).each do |variant|
              @variants_processed_counter += 1
              @failed_variant_counter += genotype.add_typed_location(@ex.extract_type(variant))
            end
          end

          def process_test_type(genotype, record)
            # cludge to handle their change in field mapping...
            reason = record.raw_fields['referral reason']
            unless reason.nil?
              genotype.
                add_molecular_testing_type_strict(TEST_TYPE_MAP[reason.downcase.strip])
            end
            mtype = record.raw_fields['moleculartestingtype']
            unless mtype.nil?
              genotype.
                add_molecular_testing_type_strict(TEST_TYPE_MAP[mtype.downcase.strip])
            end
          end

          def process_raw_genotype(genotype, record)
            # **************** These are dependant on the format change *****************
            geno = record.raw_fields['genotype']
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

          def add_scope_from_service_category(service_category, genotype)
            return if service_category.blank?

            if service_category.downcase.strip == 'o'
              genotype.add_test_scope(:full_screen)
            else
              genotype.add_test_scope(:targeted_mutation)
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
