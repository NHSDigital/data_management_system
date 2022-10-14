module Import
  module Brca
    module Providers
      module Oxford
        # Process Oxford-specific record details into generalized internal genotype format
        class OxfordHandler < Import::Germline::ProviderHandler
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

          BRCA_REGEX = /(?<brca>BRCA1|
                                BRCA2|
                                BRIP1|
                                CDK4|
                                CDKN2A|
                                CHEK2|
                                MLH1|
                                MSH2|
                                MSH6|
                                PALB2|
                                PMS2|
                                PTEN|
                                RAD51C|
                                RAD51D|
                                STK11|
                                TP53)/ix.freeze

          RECORD_EXEMPTIONS = ['c.[-835C>T]+[=]', 'Deletion of whole PTEN gene',
                               'c.[-904_-883dup ]+[=]', 'whole gene deletion',
                               'Deletion partial exon 11 and exons 12-15',
                               'deletion BRCA1 exons 21-24', 'deletion BRCA1 exons 21-24',
                               'deletion BRCA1 exons 1-17', 'whole gene duplication'].freeze

          PROTEIN_REGEX = /p\.\[?\(?(?<impact>.+)(?:\))|
                           p\.\[(?<impact>[a-z0-9*]+)\]|
                           p\.(?<impact>[a-z]+[0-9]+[a-z]+)/ix.freeze

          CDNA_REGEX = /c\.\[?(?<cdna>[0-9]+.+[a-z]+)\]?/i.freeze

          EXON_REGEX = /(?<variant>del|inv|dup).+ion\s(?<of>of\s)?
                        exon(?<s>s)?\s?(?<location>[0-9]+(?<moreexon>-[0-9]+)?)|
                        exon(?<s>s)?\s?(?<location>[0-9]+(?<moreexon>-[0-9]+)?)
                        \s(?<variant>del|inv|dup).+ion/ix.freeze

          GENOMICCHANGE_REGEX = /Chr(?<chromosome>\d+)\.hg
                                 (?<genome_build>\d+):g\.(?<effect>.+)/ix.freeze
          def process_fields(record)
            genotype = Import::Brca::Core::GenotypeBrca.new(record)
            genotype.add_passthrough_fields(record.mapped_fields,
                                            record.raw_fields,
                                            PASS_THROUGH_FIELDS)
            assign_test_scope(genotype, record)
            extract_variantpathclass(genotype, record)
            assign_test_type(genotype, record)
            process_variants(genotype, record)
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

          def assign_test_type(genotype, record)
            return if record.raw_fields['moleculartestingtype'].nil?

            if record.raw_fields['moleculartestingtype'] == 'pre-symptomatic'
              genotype.add_molecular_testing_type('predictive')
            else genotype.add_molecular_testing_type('diagnostic')
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
            if ashkenazi?(record)
              genotype.add_test_scope(:aj_screen)
            elsif polish?(record)
              genotype.add_test_scope(:polish_screen)
            elsif targeted?(record)
              genotype.add_test_scope(:targeted_mutation)
            elsif full_screen?(record)
              genotype.add_test_scope(:full_screen)
            elsif null_testscope?(record)
              targeted_scope_from_nullscope(genotype, record)
            else
              genotype.add_test_scope(:no_genetictestscope)
            end
          end

          def process_variants(genotype, record)
            return if record.mapped_fields['codingdnasequencechange'].nil?

            if CDNA_REGEX.match(record.mapped_fields['codingdnasequencechange'])
              genotype.add_gene_location($LAST_MATCH_INFO[:cdna])
              genotype.add_status(2)
              @logger.debug "SUCCESSFUL cdna change parse for: #{$LAST_MATCH_INFO[:cdna]}"
            elsif EXON_REGEX.match(record.mapped_fields['codingdnasequencechange'])
              # genotype.add_variant_type($LAST_MATCH_INFO[:variant])
              # genotype.add_exon_location($LAST_MATCH_INFO[:location])
              # genotype.add_status(2)
              add_exonic_variant(record, genotype)
            elsif normal?(record)
              genotype.add_status(1)
            elsif RECORD_EXEMPTIONS.include? record.mapped_fields['codingdnasequencechange']
              extract_exemptions_from_record(genotype, record)
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
            if [7, 8, 79, 865, 3186, 2744, 2804, 3394, 62, 76,
                590, 3615, 3616, 20, 18].include? gene
              add_oxford_gene(gene, genotype, genotypes)
            elsif BRCA_REGEX.match(synonym)
              add_oxford_gene(BRCA_REGEX.match(synonym)[:brca], genotype, genotypes)
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

          def normal?(record)
            return if record.mapped_fields['codingdnasequencechange'].nil?

            record.mapped_fields['codingdnasequencechange'].scan(%r{N/A|normal}i).size.positive?
          end

          def full_screen?(record)
            return if record.raw_fields['scope / limitations of test'].nil?

            geneticscope = record.raw_fields['scope / limitations of test']
            geneticscope.scan(/panel|scree(n|m)|brca|hcs|panel/i).size.positive?
          end

          def targeted?(record)
            return if record.raw_fields['scope / limitations of test'].nil?

            geneticscope = record.raw_fields['scope / limitations of test']
            geneticscope.scan(/targeted|proband/i).size.positive?
          end

          def ashkenazi?(record)
            return if record.raw_fields['scope / limitations of test'].nil?

            geneticscope = record.raw_fields['scope / limitations of test']
            geneticscope.scan(/ashkenazi/i).size.positive?
          end

          def polish?(record)
            return if record.raw_fields['scope / limitations of test'].nil?

            geneticscope = record.raw_fields['scope / limitations of test']
            geneticscope.scan(/polish/i).size.positive?
          end

          def null_testscope?(record)
            geneticscope = record.raw_fields['scope / limitations of test']
            geneticscope.nil?
          end

          def add_exonic_variant(record, genotype)
            return if record.raw_fields['scope / limitations of test'].nil?

            exon_info = record.mapped_fields['codingdnasequencechange']
            genotype.add_variant_type(EXON_REGEX.match(exon_info)[:variant])
            genotype.add_exon_location(EXON_REGEX.match(exon_info)[:location])
            genotype.add_status(2)
          end

          def targeted_scope_from_nullscope(genotype, record)
            return if record.raw_fields['moleculartestingtype'].nil?

            testtype = record.raw_fields['moleculartestingtype']
            if testtype.scan(/symptomatic/i).size.positive?
              genotype.add_test_scope(:targeted_mutation)
            elsif testtype.scan(/diagnostic/i).size.positive?
              genotype.add_test_scope(:full_screen)
            end
          end

          def extract_exemptions_from_record(genotype, record)
            return if record.mapped_fields['codingdnasequencechange'].nil?

            exemptions = record.mapped_fields['codingdnasequencechange']
            if exemptions.scan(/c\./).size.positive?
              genotype.add_gene_location(exemptions.gsub(/[\[\]+=]+/, ''))
              genotype.add_status(2)
            elsif exemptions.scan(/(?<delinsdup>del|ins|dup)/i).size.positive?
              genotype.add_variant_type($LAST_MATCH_INFO[:delinsdup])
              if exemptions.scan(/(?<exno>[0-9]+-[0-9]+)/i).size.positive?
                genotype.add_exon_location($LAST_MATCH_INFO[:exno])
              end
              genotype.add_status(2)
            end
            genotype
          end

          def add_oxford_gene(genevalue, genotype, genotypes)
            genotype.add_gene(genevalue)
            @logger.debug "SUCCESSFUL gene parse for:#{genevalue}"
            genotypes << genotype
          end

          def extract_variantpathclass(genotype, record)
            return if record.mapped_fields['variantpathclass'].nil? ||
                      record.mapped_fields['variantpathclass'].to_i.zero?

            varpathclass = record.mapped_fields['variantpathclass'].to_i
            genotype.add_variant_class(varpathclass)
          end
        end
      end
    end
  end
end
