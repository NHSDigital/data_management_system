module Import
  module Brca
    module Providers
      module Oxford
        # Process Oxford-specific record details into generalized internal genotype format
        class OxfordHandler < Import::Brca::Core::ProviderHandler
          TEST_SCOPE_MAP = { 'brca_multiplicom'           => :full_screen,
                             'breast-tp53 panel'          => :full_screen,
                             'breast-uterine-ovary panel' => :full_screen,
                             'targeted'                   => :targeted_mutation }.freeze

          TEST_METHOD_MAP = { 'Sequencing, Next Generation Panel (NGS)' => :ngs,
                              'Sequencing, Dideoxy / Sanger'            => :sanger }.freeze

          PASS_THROUGH_FIELDS = %w[age consultantcode
                                   servicereportidentifier
                                   providercode
                                   authoriseddate
                                   requesteddate
                                   variantpathclass
                                   sampletype
                                   referencetranscriptid].freeze

          BRCA_REGEX = /(?<brca>BRCA(1|2))/i.freeze
          PROTEIN_REGEX = /p\.\[(?<impact>(.*?))\]|p\..+/i.freeze
          CDNA_REGEX = /c\.\[?(?<cdna>[0-9]+.+[a-z])\]?/i.freeze
          GENOMICCHANGE_REGEX = /Chr(?<chromosome>\d+)\.hg
                                 (?<genome_build>\d+):g\.(?<effect>.+)/ix.freeze
          def process_fields(record)
            genotype = Import::Brca::Core::GenotypeBrca.new(record)
            genotype.add_passthrough_fields(record.mapped_fields,
                                            record.raw_fields,
                                            PASS_THROUGH_FIELDS)
            assign_method(genotype, record)
            assign_test_scope(genotype, record)
            assign_test_type(genotype, record)
            process_cdna_change(genotype, record)
            process_protein_impact(genotype, record)
            assign_genomic_change(genotype, record)
            assign_servicereportidentifier(genotype, record)
            add_organisationcode_testresult(genotype)
            res = process_gene(genotype, record)
            res&.each { |cur_genotype| @persister.integrate_and_store(cur_genotype) }
          end

          def add_organisationcode_testresult(genotype)
            genotype.attribute_map['organisationcode_testresult'] = '698C0'
          end

          def assign_method(genotype, record)
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
            Maybe(record.raw_fields['moleculartestingtype']).each do |ttype|
              if ttype.downcase != 'diagnostic'
                @logger.warn "Oxford provided test type: #{ttype}; expected" \
                             'diagnostic only'
              end
              # TODO: check that 'diagnostic' is exactly how it comes through
              genotype.add_molecular_testing_type_strict(ttype)
            end
          end

          def assign_servicereportidentifier(genotype, record)
            if record.raw_fields['investigationid']
              genotype.attribute_map['servicereportidentifier'] =
                record.raw_fields['investigationid']
            else
              @logger.debug 'Servicereportidentifier missing for this record'
            end
          end

          def assign_test_scope(genotype, record)
            Maybe(record.raw_fields['scope / limitations of test']).each do |ttype|
              scope = TEST_SCOPE_MAP[ttype.downcase.strip]
              genotype.add_test_scope(scope) if scope
            end
          end

          def process_cdna_change(genotype, record)
            if CDNA_REGEX.match(record.mapped_fields['codingdnasequencechange'])
              genotype.add_gene_location($LAST_MATCH_INFO[:cdna])
              @logger.debug "SUCCESSFUL cdna change parse for: #{$LAST_MATCH_INFO[:cdna]}"
            elsif /Normal/i.match(record.raw_fields['codingdnasequencechange'])
              genotype.add_status(1)
            else
              @logger.debug 'FAILED cdna change parse'
            end
          end

          def process_protein_impact(genotype, record)
            case record.raw_fields['proteinimpact']
            when PROTEIN_REGEX
              genotype.add_protein_impact($LAST_MATCH_INFO[:impact])
              @logger.debug "SUCCESSFUL protein change parse for: #{$LAST_MATCH_INFO[:impact]}"
            else
              @logger.debug 'FAILED protein change parse'
            end
          end

          def process_gene(genotype, record)
            genotypes = []
            gene      = record.mapped_fields['gene'].to_i
            synonym   = record.raw_fields['sinonym'].to_s
            if [7, 8, 79, 451, 3186].include? gene
              genotype.add_gene(gene)
              @logger.debug "SUCCESSFUL gene parse for:#{record.mapped_fields['gene'].to_i}"
              genotypes << genotype
            elsif BRCA_REGEX.match(synonym)
              @logger.debug "SUCCESSFUL gene parse from #{synonym}"
              genotype.add_gene($LAST_MATCH_INFO[:brca])
              genotypes << genotype
            else
              @logger.debug 'FAILED gene parse'
            end
            genotypes
          end

          def assign_genomic_change(genotype, record)
            Maybe(record.raw_fields['genomicchange']).each do |raw_change|
              if GENOMICCHANGE_REGEX.match(raw_change)
                genotype.add_genome_build($LAST_MATCH_INFO[:genome_build].to_i)
                genotype.add_parsed_genomic_change($LAST_MATCH_INFO[:chromosome],
                                                   $LAST_MATCH_INFO[:effect])
              elsif /Normal/i.match(raw_change)
                genotype.add_status(1)
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
