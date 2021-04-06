require 'pry'
require 'possibly'

module Import
  module Colorectal
    module Providers
      module Newcastle
        # Process Newcastle-specific record details into generalized internal genotype format
        class NewcastleHandlerColorectal < Import::Brca::Core::ProviderHandler
          include ExtractionUtilities
          TEST_SCOPE_MAP_COLO = { 'brca-ng' => :full_screen,
                                  'brca-rapid screen' => :full_screen,
                                  'brca top up' => :full_screen,
                                  'brca-pred' => :targeted_mutation,
                                  'brca1' => :targeted_mutation,
                                  'brca2' => :targeted_mutation } .freeze

          TEST_TYPE_MAP_COLO = { 'diag - symptoms' => :diagnostic,
                                 'diagnosis' => :diagnostic,
                                 'diagnostic' => :diagnostic,
                                 'diagnostic test' => :diagnostic,
                                 'presymptomatic' => :predictive,
                                 'predictive' => :predictive,
                                 'predictive test' => :predictive,
                                 'carrier' => :carrier,
                                 'carrier test' => :carrier,
                                 'prenatal diagnosis' => :prenatal } .freeze

          TEST_SCOPE_FROM_TYPE_MAP_COLO = { 'carrier' => :targeted_mutation,
                                            'carrier test' => :targeted_mutation,
                                            'diag - symptoms' => :full_screen,
                                            'diagnosis' => :full_screen,
                                            'diagnostic' => :full_screen,
                                            'diagnostic test' => :full_screen,
                                            'diagnostic/forward' => :full_screen,
                                            'bmt' => :targeted_mutation,
                                            'family studies' => :targeted_mutation,
                                            'predictive' => :targeted_mutation,
                                            'predictive test' => :targeted_mutation,
                                            'presymptomatic' => :targeted_mutation,
                                            'presymptomatic test' => :targeted_mutation,
                                            'storage' => :full_screen } .freeze

          PASS_THROUGH_FIELDS_COLO = %w[age authoriseddate
                                        requesteddate
                                        specimentype
                                        providercode
                                        consultantcode
                                        servicereportidentifier] .freeze
          FIELD_NAME_MAPPINGS_COLO = { 'consultantcode' => 'practitionercode',
                                       'ngs sample number' => 'servicereportidentifier' } .freeze

          # CDNA_REGEX=/c\.(?<cdna>[0-9]*.>[A-Za-z]+.+);|c\.(?<cdna>[0-9]+.+[0-9]+[A-Za-z]+.+)/i .freeze
          # CDNA_REGEX = /c\.(?<cdna>[0-9]+.>[A-Za-z]+);|c\.(?<cdna>[0-9]+.+[0-9]+[A-Za-z]+.+)/i .freeze
          CDNA_REGEX = /c\.(?<cdna>[0-9]+[A-Za-z]+>[A-Za-z]+)|
                        c\.(?<cdna>[0-9]+.(?:[0-9]+)[A-Za-z]+>[A-Z]+)|
                        c\.(?<cdna>[0-9]+.[0-9].[0-9]+.[0-9][A-Za-z]+)|
                        c\.(?<cdna>[0-9]+[A-Za-z]+)|
                        c\.(?<cdna>\*[0-9]+.\*[0-9]+[a-z]+)/ix .freeze

          IMPACT_REGEX = /.p\.(?<impact>[A-Za-z]+[0-9]+[A-Za-z]+)/i .freeze

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
                                                STK11|
                                                GREM1|
                                                NTHL1)/ix .freeze # Added by Francesco
          HNPCC = %w[MLH1 MSH2 MSH6 PMS2 EPCAM] .freeze
          HNPCCMLPA = %w[MLH1 MSH2 MSH6 EPCAM] .freeze
          COLORECTALCANCER = %w[APC BMPR1A EPCAM GREM1 MLH1 MSH2 MSH6 MUTYH NTHL1 PMS2
                                POLD1 POLE PTEN SMAD4 STK11] .freeze
          FAPMAP = %w[APC MUTYH] .freeze

          def initialize(batch)
            @records_attempted_counter = 0
            @failed_variant_counter = 0
            @variants_processed_counter = 0
            @ex = LocationExtractor.new
            super
          end

          def attach_persister(batch)
            @persister = NewcastlePersister.new(batch)
          end

          def process_fields(record)
            @records_attempted_counter += 1
            genocolorectal = Import::Colorectal::Core::Genocolorectal.new(record)
            genocolorectal.add_passthrough_fields(record.mapped_fields,
                                                  record.raw_fields,
                                                  PASS_THROUGH_FIELDS_COLO,
                                                  FIELD_NAME_MAPPINGS_COLO)
            identifier = record.raw_fields['ngs sample number']
            genocolorectal.add_servicereportidentifier(identifier) unless identifier.nil?
            process_test_type(genocolorectal, record)
            add_organisationcode_testresult(genocolorectal)
            process_investigation_code(genocolorectal, record)
            res = process_gene_colorectal(genocolorectal, record) # Added by Francesco
            res.map { |cur_genotype| @persister.integrate_and_store(cur_genotype) }
          end

          def add_organisationcode_testresult(genocolorectal)
            genocolorectal.attribute_map['organisationcode_testresult'] = '699A0'
          end

          def process_investigation_code(genocolorectal, record)
            moltesttype = record.raw_fields['moleculartestingtype']
            if record.raw_fields['service category'].to_s.downcase.strip == 'o' ||
               record.raw_fields['service category'].to_s.downcase.strip == '0' ||
               record.raw_fields['service category'].to_s.downcase.strip == 'c'
              @logger.debug 'Found O/C/0'
              add_scope_from_service_category(record.raw_fields['service category'].to_s, genocolorectal)
            elsif TEST_SCOPE_FROM_TYPE_MAP_COLO.has_key?(moltesttype&.downcase.strip)
              genocolorectal.add_test_scope(TEST_SCOPE_FROM_TYPE_MAP_COLO[moltesttype.downcase.strip])
              @logger.debug 'ADDED SCOPE FROM TYPE'
            else
              @logger.debug 'NOTHING TO BE DONE'
            end
          end

          def process_variant_details(genocolorectal, record)
            variantclass = Maybe(record.mapped_fields['variantpathclass']).
                           or_else(Maybe(record.raw_fields['variant type']))
            genocolorectal.add_variant_class(variantclass)
          end

          def process_test_type(genocolorectal, record)
            # cludge to handle their change in field mapping...
            reason = record.raw_fields['referral reason']
            genocolorectal.add_molecular_testing_type_strict(TEST_TYPE_MAP_COLO[reason.downcase.strip]) \
                           unless reason.nil?
            mtype = record.raw_fields['moleculartestingtype']
            genocolorectal.add_molecular_testing_type_strict(TEST_TYPE_MAP_COLO[mtype.downcase.strip]) \
                           unless mtype.nil?
          end

          def process_raw_genotype(genocolorectal, record)
            # **************** These are dependant on the format change *****************
            geno = record.raw_fields['teststatus']
            case geno
            when /nmd/, /benign/, /Benign/
              genocolorectal.add_status(1)
            when /variant/, /abnormal/, /pathogenic/, /Pathogenic/
              genocolorectal.add_status(2)
            when /het/, /hemi/
              genocolorectal.add_status(2)
              genocolorectal.add_zygosity(geno)
            when /fail/
              genocolorectal.add_status(9)
            when nil
              genocolorectal.add_status(1)
            else
              @logger.info "Encountered unfamiliar teststatus string: #{geno}"
            end
          end

          def add_cdna_change_from_report(genocolorectal, record)
            case record.raw_fields['genotype']
            when CDNA_REGEX
              genocolorectal.add_gene_location($LAST_MATCH_INFO[:cdna])
              @logger.debug "SUCCESSFUL cdna change parse for: #{$LAST_MATCH_INFO[:cdna]}"
            end
          end

          def process_protein_impact(genocolorectal, record)
            if IMPACT_REGEX.match(record.raw_fields['genotype'])
              genocolorectal.add_protein_impact($LAST_MATCH_INFO[:impact])
              @logger.debug "SUCCESSFUL PROTEIN change parse for: #{$LAST_MATCH_INFO[:impact]}"
            else
              @logger.debug "UNSUCCESSFUL PROTEIN PARSE FOR #{record.raw_fields['genotype']}"
            end
          end

          def add_scope_from_service_category(service_category, genocolorectal)
            return if service_category.nil? || service_category.empty?

            if service_category.downcase.strip == 'o' ||
               service_category.downcase.strip == 'c' ||
               service_category.downcase.strip == '0'
              genocolorectal.add_test_scope(:full_screen)
            end
          end

          def process_gene_colorectal(genocolorectal, record)
            colorectal_input = record.raw_fields['gene']
            moltesttype = record.raw_fields['moleculartestingtype']
            genotypes = []
            if COLORECTAL_GENES_REGEX.match(colorectal_input) &&
               !record.raw_fields['genotype'].empty? &&
               TEST_SCOPE_FROM_TYPE_MAP_COLO[moltesttype&.downcase.strip] == :targeted_mutation
              genocolorectal.add_gene_colorectal($LAST_MATCH_INFO[:colorectal])
              add_cdna_change_from_report(genocolorectal, record)
              process_protein_impact(genocolorectal, record)
              process_raw_genotype(genocolorectal, record)
              process_variant_details(genocolorectal, record)
              genotypes << genocolorectal
            elsif COLORECTAL_GENES_REGEX.match(colorectal_input) &&
                  !record.raw_fields['genotype'].empty? &&
                  (TEST_SCOPE_FROM_TYPE_MAP_COLO[moltesttype&.downcase.strip] == :full_screen ||
                  record.raw_fields['service category'].to_s.downcase.strip.match(/o|c|0/))
              genocolorectal1 = genocolorectal.dup_colo
              if record.raw_fields['investigation code'].downcase.strip == 'hnpcc'
                neg_genes = HNPCC - [$LAST_MATCH_INFO[:colorectal]]
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
                add_cdna_change_from_report(genocolorectal, record)
                process_protein_impact(genocolorectal, record)
                process_raw_genotype(genocolorectal, record)
                process_variant_details(genocolorectal, record)
                genotypes.append(genocolorectal)
              elsif record.raw_fields['investigation code'].downcase.strip == 'hnpcc-mlpa'
                neg_genes = HNPCCMLPA - [$LAST_MATCH_INFO[:colorectal]]
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
                add_cdna_change_from_report(genocolorectal, record)
                process_protein_impact(genocolorectal, record)
                process_raw_genotype(genocolorectal, record)
                process_variant_details(genocolorectal, record)
                genotypes.append(genocolorectal)
              elsif record.raw_fields['investigation code'].downcase.strip == 'colorectal cancer'
                neg_genes = COLORECTALCANCER - [$LAST_MATCH_INFO[:colorectal]]
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
                add_cdna_change_from_report(genocolorectal, record)
                process_protein_impact(genocolorectal, record)
                process_raw_genotype(genocolorectal, record)
                process_variant_details(genocolorectal, record)
                genotypes.append(genocolorectal)
              elsif record.raw_fields['investigation code'].downcase.strip == 'fap/map'
                neg_genes = FAPMAP - [$LAST_MATCH_INFO[:colorectal]]
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
                add_cdna_change_from_report(genocolorectal, record)
                process_protein_impact(genocolorectal, record)
                process_raw_genotype(genocolorectal, record)
                process_variant_details(genocolorectal, record)
                genotypes.append(genocolorectal)
              elsif record.raw_fields['investigation code'].downcase.strip == 'fap'
                genocolorectal.add_gene_colorectal($LAST_MATCH_INFO[:colorectal])
                add_cdna_change_from_report(genocolorectal, record)
                process_protein_impact(genocolorectal, record)
                process_raw_genotype(genocolorectal, record)
                process_variant_details(genocolorectal, record)
                genotypes.append(genocolorectal)
              end
              genotypes
            elsif (colorectal_input.blank? && record.raw_fields['genotype'].blank? &&
                  TEST_SCOPE_FROM_TYPE_MAP_COLO[moltesttype&.downcase.strip] == :full_screen) ||
                  (colorectal_input.blank? && record.raw_fields['genotype'].blank? &&
                  record.raw_fields['service category'].to_s.downcase.strip.match(/o|c|0/))
              if record.raw_fields['investigation code'].downcase.strip == 'hnpcc'
                HNPCC.each do |genes|
                  genocolorectal1 = genocolorectal.dup_colo
                  genocolorectal1.add_status(1)
                  genocolorectal1.add_gene_colorectal(genes)
                  genotypes << genocolorectal1
                end
              elsif record.raw_fields['investigation code'].downcase.strip == 'hnpcc-mlpa'
                HNPCCMLPA.each do |genes|
                  genocolorectal1 = genocolorectal.dup_colo
                  genocolorectal1.add_status(1)
                  genocolorectal1.add_gene_colorectal(genes)
                  genotypes << genocolorectal1
                end
              elsif record.raw_fields['investigation code'].downcase.strip == 'colorectal cancer'
                COLORECTALCANCER.each do |genes|
                  genocolorectal1 = genocolorectal.dup_colo
                  genocolorectal1.add_gene_colorectal(genes)
                  genocolorectal1.add_status(1)
                  genotypes << genocolorectal1
                end
              elsif record.raw_fields['investigation code'].downcase.strip == 'fap/map'
                FAPMAP.each do |genes|
                  genocolorectal1 = genocolorectal.dup_colo
                  genocolorectal1.add_gene_colorectal(genes)
                  genocolorectal1.add_status(1)
                  genotypes << genocolorectal1
                end
              elsif record.raw_fields['investigation code'].downcase.strip == 'fap' ||
                    record.raw_fields['investigation code'].downcase.strip == 'fap-mlpa'
                genocolorectal.add_gene_colorectal('APC')
                genocolorectal.add_status(1)
                genotypes << genocolorectal
              end
            elsif colorectal_input.blank? && record.raw_fields['genotype'].blank? &&
                  TEST_SCOPE_FROM_TYPE_MAP_COLO[moltesttype&.downcase.strip] == :targeted_mutation ||
                  TEST_SCOPE_FROM_TYPE_MAP_COLO[moltesttype&.downcase.strip].nil?
              genocolorectal.add_status(:unknown)
              genotypes << genocolorectal
            else
              @logger.debug "FAILED gene parse for  #{colorectal_input}"
              genocolorectal.add_status(1)
              genotypes << genocolorectal
            end
            genotypes
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
