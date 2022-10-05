module Import
  module Colorectal
    module Providers
      module Oxford
        # Process Oxford-specific record details into generalized internal genotype format
        class OxfordHandlerColorectal < Import::Germline::ProviderHandler
          TEST_METHOD_MAP = { 'Sequencing, Next Generation Panel (NGS)' => :ngs,
                              'Sequencing, Dideoxy / Sanger'            => :sanger }.freeze

          PASS_THROUGH_FIELDS = %w[age consultantcode
                                   servicereportidentifier
                                   providercode
                                   authoriseddate
                                   requesteddate
                                   sampletype
                                   referencetranscriptid].freeze

          COLORECTAL_GENES_REGEX = /(?<colorectal>APC|
                                                BMPR1A|
                                                EPCAM|
                                                MLH1|
                                                MSH2|
                                                MSH6|
                                                MUTYH|
                                                GREM1|
                                                PMS2|
                                                POLD1|
                                                POLE|
                                                PTEN|
                                                SMAD4|
                                                STK11|
                                                NTHL1)/xi.freeze

          FULL_SCREEN_REGEX = /(?<fullscreen>Panel|
          full\sgene\sscreen|
          full.+screen|
          full.+screem|
          fullscreen|
          BRCA_Multiplicom|
          HCS|
          BRCA1|
          BRCA2)/xi .freeze

          PROTEIN_REGEX            = /p\.\[(?<impact>(.*?))\]|p\..+/i.freeze
          CDNA_REGEX               = /c\.\[?(?<cdna>[0-9]+.+[a-z])\]?/i.freeze
          GENOMICCHANGE_REGEX      = /Chr(?<chromosome>\d+)\.hg(?<genome_build>\d+)
                                     :g\.(?<effect>.+)/xi.freeze
          VARPATHCLASS_REGEX       = /[1-5]/i.freeze
          CHROMOSOME_VARIANT_REGEX = /(?<chromvar>del|ins|dup)/i.freeze

          def process_fields(record)
            genocolorectal = Import::Colorectal::Core::Genocolorectal.new(record)
            genocolorectal.add_passthrough_fields(record.mapped_fields,
                                                  record.raw_fields,
                                                  PASS_THROUGH_FIELDS)
            assign_method(genocolorectal, record)
            assign_test_scope(genocolorectal, record)
            assign_test_type(genocolorectal, record)
            assign_genomic_change(genocolorectal, record)
            assign_servicereportidentifier(genocolorectal, record)
            assign_variantpathclass(genocolorectal, record)
            add_organisationcode_testresult(genocolorectal)
            res = process_records(genocolorectal, record)
            res.each { |cur_genotype| @persister.integrate_and_store(cur_genotype) }
          end

          def add_organisationcode_testresult(genocolorectal)
            genocolorectal.attribute_map['organisationcode_testresult'] = '698C0'
          end

          def assign_method(genocolorectal, record)
            Maybe(record.raw_fields['karyotypingmethod']).each do |raw_method|
              method = TEST_METHOD_MAP[raw_method]
              if method
                genocolorectal.add_method(method)
              else
                @logger.warn "Unknown method: #{raw_method}; possibly need to update map"
              end
            end
          end

          def assign_test_type(genocolorectal, record)
            Maybe(record.raw_fields['moleculartestingtype']).each do |ttype|
              if ttype.downcase != 'diagnostic' && ttype.downcase != 'confirmatory'
                @logger.warn "Oxford provided test type: #{ttype}; expected" \
                             'diagnostic only'
              end
              genocolorectal.add_molecular_testing_type_strict(ttype)
            end
          end

          def assign_variantpathclass(genocolorectal, record)
            Maybe(record.mapped_fields['variantpathclass']).each do |varpathclass|
              if (1..5).cover? varpathclass.scan(VARPATHCLASS_REGEX).join.to_i
                genocolorectal.add_variant_class(varpathclass.scan(VARPATHCLASS_REGEX).join.to_i)
              end
            end
          end

          def assign_servicereportidentifier(genocolorectal, record)
            if record.raw_fields['investigationid']
              genocolorectal.attribute_map['servicereportidentifier'] =
                record.raw_fields['investigationid']
            else
              @logger.debug 'Servicereportidentifier missing for this record'
            end
          end

          def assign_test_scope(genocolorectal, record)
            Maybe(record.raw_fields['scope / limitations of test']).each do |ttype|
              if ashkenazi?(ttype)
                genocolorectal.add_test_scope(:aj_screen)
              elsif polish?(ttype)
                genocolorectal.add_test_scope(:polish_screen)
              elsif targeted?(ttype)
                genocolorectal.add_test_scope(:targeted_mutation)
              elsif full_screen?(ttype)
                genocolorectal.add_test_scope(:full_screen)
              else @logger.debug 'Unable to parse genetic test scope'
              end
            end
          end

          def ashkenazi?(scopecolumn)
            scopecolumn.match(/ashkenazi/i)
          end

          def polish?(scopecolumn)
            scopecolumn.match(/polish/i)
          end

          def targeted?(scopecolumn)
            scopecolumn.match(/targeted/i) || scopecolumn == 'RD Proband Confirmation'
          end

          def full_screen?(scopecolumn)
            FULL_SCREEN_REGEX.match(scopecolumn)
          end

          def process_cdna_change(record, genocolorectal, genotypes)
            cdna             = record.raw_fields['codingdnasequencechange']
            cdna_match       = CDNA_REGEX.match(cdna)
            chromosome_match = CHROMOSOME_VARIANT_REGEX.match(cdna)
            if cdna_match
              process_cdna_match(genocolorectal, genotypes, cdna_match)
            elsif chromosome_match
              process_chromosome_variant(genocolorectal, genotypes, chromosome_match)
            else
              genocolorectal.add_status(1)
              genotypes.append(genocolorectal)
              @logger.debug 'FAILED cdna change parse'
            end
          end

          def process_cdna_match(genocolorectal, genotypes, cdna_match)
            genocolorectal.add_gene_location(cdna_match[:cdna])
            genocolorectal.add_status(2)
            genotypes.append(genocolorectal)
            @logger.debug "SUCCESSFUL cdna change parse for: #{cdna_match[:cdna]}"
          end

          def process_chromosome_variant(genocolorectal, genotypes, chromosome_match)
            genocolorectal.add_variant_type(chromosome_match[:chromvar])
            genocolorectal.add_status(2)
            genotypes.append(genocolorectal)
            @logger.debug 'SUCCESSFUL chromosomal variant parse for: ' \
                          "#{chromosome_match[:chromvar]}"
          end

          def process_protein_impact(record, genocolorectal, genotypes)
            protein = record.raw_fields['proteinimpact']
            if PROTEIN_REGEX.match(protein)
              genocolorectal.add_protein_impact($LAST_MATCH_INFO[:impact])
              genotypes.append(genocolorectal)
              @logger.debug "SUCCESSFUL protein change parse for: #{$LAST_MATCH_INFO[:impact]}"
            else
              @logger.debug 'FAILED protein change parse'
            end
          end

          def process_gene(record, genocolorectal, genotypes)
            gene = record.raw_fields['gene'] unless record.raw_fields['gene'].nil?
            if COLORECTAL_GENES_REGEX.match(gene.upcase)
              genocolorectal.add_gene_colorectal($LAST_MATCH_INFO[:colorectal])
              genotypes.append(genocolorectal)
              @logger.debug "SUCCESSFUL gene parse for: #{gene}"
            else
              @logger.debug 'Failed gene parse'
            end
          end

          def process_records(genocolorectal, record)
            genotypes = []
            if COLORECTAL_GENES_REGEX.match(record.raw_fields['gene'].upcase)
              process_gene(record, genocolorectal, genotypes)
              process_cdna_change(record, genocolorectal, genotypes)
              process_protein_impact(record, genocolorectal, genotypes)
            end
            genotypes
          end

          def assign_genomic_change(genocolorectal, record)
            Maybe(record.raw_fields['genomicchange']).each do |raw_change|
              if GENOMICCHANGE_REGEX.match(raw_change)
                genocolorectal.add_genome_build($LAST_MATCH_INFO[:genome_build].to_i)
                genocolorectal.add_parsed_genomic_change($LAST_MATCH_INFO[:chromosome],
                                                         $LAST_MATCH_INFO[:effect])
              elsif /Normal/i.match(raw_change)
                genocolorectal.add_status(1)
              else
                @logger.warn "Could not process, so adding raw genomic change: #{raw_change}"
              end
            end
          end
        end
      end
    end
  end
end
