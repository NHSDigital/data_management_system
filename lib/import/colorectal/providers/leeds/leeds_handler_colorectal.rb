# require_relative 'report_extractor'
require 'pry'

module Import
  module Colorectal
    module Providers
      module Leeds
        # rubocop:disable Metrics/ClassLength
        # Leeds importer for colorectal
        class LeedsHandlerColorectal < Import::Germline::ProviderHandler
          TEST_SCOPE_MAP_COLO_COLO = { 'carrier test' => :targeted_mutation,
                                       'diagnostic' => :full_screen,
                                       'diagnostic; fap' => :full_screen,
                                       'diagnostic; lynch' => :full_screen,
                                       'diagnostic; pms2' => :full_screen,
                                       'confirmation' => :targeted_mutation,
                                       'predictive' => :targeted_mutation,
                                       'predictive test' => :targeted_mutation,
                                       'familial' => :targeted_mutation,
                                       'r209' => :full_screen,
                                       'r209.1' => :full_screen,
                                       'r210.2' => :full_screen,
                                       'r211.1' => :full_screen } .freeze

          TEST_TYPE_MAP_COLO = { 'carrier test' => :carrier,
                                 'diagnostic' => :diagnostic,
                                 'diagnostic; fap' => :diagnostic,
                                 'diagnostic; lynch' => :diagnostic,
                                 'confirmation' => :diagnostic,
                                 'predictive' => :predictive,
                                 'predictive test' => :predictive,
                                 'familial' => :predictive } .freeze

          PASS_THROUGH_FIELDS = %w[age consultantcode
                                   providercode
                                   receiveddate
                                   authoriseddate
                                   requesteddate
                                   servicereportidentifier
                                   organisationcode_testresult
                                   specimentype] .freeze
          FIELD_NAME_MAPPINGS = { 'consultantcode'  => 'practitionercode',
                                  'instigated_date' => 'requesteddate' } .freeze

          CDNA_REGEX = /c\.(?<cdna>[0-9]+.>[A-Za-z]+)|c\.(?<cdna>[0-9]+.[0-9]+[A-Za-z]+)/i .freeze
          PROTEIN_REGEX = /p\.\((?<impact>.\w+\d+\w+)\)/i .freeze
          TESTSTATUS_REGEX = /unaffected|neg|normal/i .freeze
          NOPATH_REGEX = /.No pathogenic variant was identified./i .freeze
          EXON_LOCATION_REGEX = /(?<exons>exons? (\d+[a-z]*(?: ?- ?\d+[a-z]*)?))/i .freeze

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
                                                NTHL1)/xi . freeze # Added by Francesco
          PATHVAR_REGEX = /((?<homohet>heterozygous|homozygous)[\w\s]+{0,2})?
                          (?<genes>APC|BMPR1A|EPCAM|GREM1|MLH1|MSH2|MSH6|MUTYH|NTHL1|PMS2|
                                   POLD1|POLE|PTEN|SMAD4|STK11)
                          \s[\w\s]+{0,2}.c\.(?<cdna>[0-9]+[A-Z]+>[A-Z]+|
                                             [0-9]+_[0-9]+[a-z]+|
                                             [0-9]+[a-z]+|
                                             [0-9]+[\W][0-9]+[a-z]+>[a-z]+|
                                             [0-9]+_[0-9]+[\W][0-9]+[a-z]+
                                             [0-9]+_[0-9]+[a-z]+|
                                             [0-9]+[\W][0-9]+_[0-9]+[a-z]+|
                                             [0-9]+[\W][0-9]+[a-z]+|
                                             [0-9]+[\W][0-9]+_[0-9]+[\W][0-9]+[a-z]+|
                                             [\W][0-9]+[a-z]+>[a-z]+).
                          (\(?p\.\(?(?<impact>[\w]+)|\(p\.\(?(?<impact>[\w]+)\))?/ix .freeze

          PATHVAR_BIGINDELS = /(?<genes>APC|BMPR1A|EPCAM|GREM1|MLH1|MSH2|MSH6|MUTYH|NTHL1|
                            PMS2|POLD1|POLE|PTEN|SMAD4|STK11).+
                             c\.(?<cdna>[0-9]+_[0-9]+.[0-9]+[a-z]+|[0-9]+.[0-9]+.[0-9]+[a-z]+)/ix .freeze

          PATHVAR_REGEX2 = /((?<homohet>heterozygous|homozygous)[\w\s]+{0,2})?\s[\w\s]+{0,2}.
                            c\.(?<cdna>[0-9]+[A-Z]+>[A-Z]+|[0-9]+_[0-9]+[a-z]+|
                            [0-9]+[a-z]+|[0-9]+[\W][0-9]+[a-z]+>[a-z]+|
                            [0-9]+_[0-9]+[\W][0-9]+[a-z]+[0-9]+_[0-9]+[a-z]+|
                            [0-9]+[\W][0-9]+_[0-9]+[a-z]+|[0-9]+[\W][0-9]+[a-z]+|
                            [0-9]+[\W][0-9]+_[0-9]+[\W][0-9]+[a-z]+|[\W][0-9]+[a-z]+>[a-z]+).
                            (\(?p\.\(?(?<impact>[\w]+)\)|\(p\.\(?(?<impact>[\w]+)\))?[\w\s]+
                            (?<genes>APC|BMPR1A|EPCAM|GREM1|MLH1|MSH2|MSH6|MUTYH|NTHL1|PMS2|POLD1|
                            POLE|PTEN|SMAD4|STK11)/ix .freeze

          PATH_TWOGENES_VARIANTS = /((heterozygous)?[\s\w]{2,})(?<path>pathogenic).(?<genes>APC|BMPR1A|
                                 EPCAM|
                                 MLH1|MSH2|MSH6|MUTYH|PMS2|POLD1|POLE|PTEN|SMAD4|STK11|GREM1|NTHL1).(sequence)?
                                 (mutation|variant)?.c\.(?<cdna>[0-9]+[A-Z]+>[A-Z]+|[0-9]+_[0-9]+[a-z]+|
                                 [0-9]+[a-z]+|[0-9]+[\W][0-9]+[a-z]+>[a-z]+|
                                 [0-9]+_[0-9]+[\W][0-9]+[a-z]+[0-9]+_[0-9]+[a-z]+|
                                 [0-9]+[\W][0-9]+_[0-9]+[a-z]+|
                                 [0-9]+[\W][0-9]+[a-z]+|[0-9]+[\W][0-9]+_[0-9]+[\W][0-9]+[a-z]+|
                                 [\W][0-9]+[a-z]+>[a-z]+).+(heterozygous)?[\s\w]{2,}
                                 (?<genes2>APC|BMPR1A|EPCAM|MLH1|MSH2|MSH6|MUTYH|PMS2|POLD1|POLE|PTEN|
                                 SMAD4|STK11|GREM1|NTHL1)[\s\w]{2,}
                                 c\.(?<cdna2>[0-9]+[A-Z]+>[A-Z]+|[0-9]+_[0-9]+[a-z]+|[0-9]+[a-z]+|
                                 [0-9]+[\W][0-9]+[a-z]+>[a-z]+|
                                 [0-9]+_[0-9]+[\W][0-9]+[a-z]+[0-9]+_[0-9]+[a-z]+|
                                 [0-9]+[\W][0-9]+_[0-9]+[a-z]+|[0-9]+[\W][0-9]+[a-z]+|
                                 [0-9]+[\W][0-9]+_[0-9]+[\W][0-9]+[a-z]+|[\W][0-9]+[a-z]+>[a-z]+)|
                                 (?<genes>APC|BMPR1A|EPCAM|MLH1|MSH2|MSH6|MUTYH|PMS2|POLD1|POLE|PTEN|
                                 SMAD4|STK11|GREM1|NTHL1)[\s\w]{2,}.c\.(?<cdna>[0-9]+[A-Z]+>[A-Z]+|
                                 [0-9]+_[0-9]+[a-z]+|[0-9]+[a-z]+|[0-9]+[\W][0-9]+[a-z]+>[a-z]+|
                                 [0-9]+_[0-9]+[\W][0-9]+[a-z]+[0-9]+_[0-9]+[a-z]+|
                                 [0-9]+[\W][0-9]+_[0-9]+[a-z]+|[0-9]+[\W][0-9]+[a-z]+|
                                 [0-9]+[\W][0-9]+_[0-9]+[\W][0-9]+[a-z]+|
                                 [\W][0-9]+[a-z]+>[a-z]+).+(heterozygous)?[\s\w]{2,}
                                 (?<genes2>APC|BMPR1A|EPCAM|MLH1|MSH2|MSH6|MUTYH|PMS2|POLD1|POLE|PTEN|
                                 SMAD4|STK11|GREM1|NTHL1)[\s\w]{2,}c\.(?<cdna2>[0-9]+[A-Z]+>[A-Z]+|
                                 [0-9]+_[0-9]+[a-z]+|[0-9]+[a-z]+|[0-9]+[\W][0-9]+[a-z]+>[a-z]+|
                                 [0-9]+_[0-9]+[\W][0-9]+[a-z]+[0-9]+_[0-9]+[a-z]+|
                                 [0-9]+[\W][0-9]+_[0-9]+[a-z]+|[0-9]+[\W][0-9]+[a-z]+|
                                 [0-9]+[\W][0-9]+_[0-9]+[\W][0-9]+[a-z]+|[\W][0-9]+[a-z]+>[a-z]+)/ix

          NOPATH_SINGLEGENE = /(?<genes>APC|BMPR1A|
                                EPCAM|GREM1|MLH1|MSH2|
                                MSH6|MUTYH|NTHL1|PMS2|
                                POLD1|POLE|PTEN|SMAD4|STK11)[\w\s]
                                +.No pathogenic variant was identified/ix .freeze

          PATHVAR_TWOGENES_REGEX = /((?<homohet>heterozygous|homozygous)[\w\s]+{0,2})?
                                     (?<genes>APC|BMPR1A|EPCAM|GREM1|MLH1|MSH2|MSH6|MUTYH|
                                     NTHL1|PMS2|POLD1|POLE|PTEN|SMAD4|STK11)
                                     \s[\w\s]+{0,2}.
                                     c\.(?<cdna>[0-9]+[A-Z]+>[A-Z]+|[0-9]+_[0-9]+[a-z]+|[0-9]+[a-z]+)
                                     .(\(?p\.\(?(?<impact>[\w]+)\)?)? (\w)+
                                     c\.(?<cdna2>[0-9]+[A-Z]+>[A-Z]+|[0-9]+_[0-9]+[a-z]+|[0-9]+[a-z]+)
                                     .(\(?p\.\(?(?<impact2>[\w]+)\)?)?/ix .freeze

          PATHVAR_EXONS_REGEX = /(?<homohet>heterozygous|homozygous)[\w\s]+{0,3}(?<deldup>deletion|duplication)[\w\s]+(?<genes>APC|BMPR1A|EPCAM|GREM1|MLH1|MSH2|MSH6|MUTYH|NTHL1|PMS2|POLD1|POLE|PTEN|SMAD4|STK11)([\w\s]+|\s)?(?<exons>exons? (\d+[a-z]*(?: ?- ?\d+[a-z]*)?))|(?<homohet>heterozygous|homozygous)[\w\s]+{0,3}(?<genes>APC|BMPR1A|EPCAM|GREM1|MLH1|MSH2|MSH6|MUTYH|NTHL1|PMS2|POLD1|POLE|PTEN|SMAD4|STK11)[\w\s]+(?<deldup>deletion|duplication)([\w\s]+|\s)?(?<exons>exons? (\d+[a-z]*(?: ?- ?\d+[a-z]*)?))/i .freeze

          ABSENT_REGEX = /is absent in this patient/i .freeze
          NO_DEL_REGEX = /this patient does not have the deletion/i .freeze
          NOMUT_REGEX = /(?<notmut>No mutations were identified in|this patient does not have|has not identified any mutations in this patient|no mutation has been identified|no evidence of a deletion or duplication)|not detected in this patient|did not identify/i .freeze
          EXON_ALTERNATIVE_REGEX = /(heterozygous)?[\s\w]{2,} (?<pathogenic>pathogenic)? (?<genes>APC|BMPR1A|EPCAM|MLH1|MSH2|MSH6|MUTYH|PMS2|POLD1|
                                    POLE|PTEN|SMAD4|STK11|GREM1|NTHL1) (?<delmut>deletion|mutation|inversion|duplication)[\s\w]{2,}(?<exons>exon(s).[0-9]+(.?)[0-9]+?)|
                                    (pathogenic)? (?<genes>APC|BMPR1A|EPCAM|MLH1|MSH2|MSH6|MUTYH|PMS2|POLD1|
                                    POLE|PTEN|SMAD4|STK11|GREM1|NTHL1)[\w\s]{0,2}(?<invdupdel>inversion|duplication|deletion)\s[\w\s]+{0,2}(?<exons>exon(s).[0-9]+(.?)[0-9]+?)|
                                    (pathogenic)? (?<invdupdel>inversion|duplication|deletion)\s[\w\s]+{0,2}(?<exons>exon(s).[0-9]+(.?)[0-9]+?) ([\w\s]+)?
                                    (?<genes>APC|BMPR1A|EPCAM|MLH1|MSH2|MSH6|MUTYH|PMS2|POLD1|
                                    POLE|PTEN|SMAD4|STK11|GREM1|NTHL1)[\w\s]{0,2}?|(familial)? pathogenic deletion of 
                                    (?<genes>APC|BMPR1A|EPCAM|MLH1|MSH2|MSH6|MUTYH|PMS2|POLD1|
                                    POLE|PTEN|SMAD4|STK11|GREM1|NTHL1) (?<delmut>deletion|mutation|inversion|duplication)[\s\w]{2,}
                                    (?<exons>exon(s).[0-9]+(.?)[0-9]+?)|(familial)? pathogenic (?<genes>APC|BMPR1A|EPCAM|MLH1|MSH2|MSH6|MUTYH|PMS2|POLD1|
                                    POLE|PTEN|SMAD4|STK11|GREM1|NTHL1) (?<delmut>deletion|mutation|inversion|duplication)/ix .freeze

          def initialize(batch)
            @extractor = ReportExtractor::GenotypeAndReportExtractor.new
            @negative_test = 0 # Added by Francesco
            @positive_test = 0 # Added by Francesco
            super
          end

          def process_fields(record)
            genocolorectal = Import::Colorectal::Core::Genocolorectal.new(record)
            genocolorectal.add_passthrough_fields(record.mapped_fields,
                                                  record.raw_fields,
                                                  PASS_THROUGH_FIELDS,
                                                  FIELD_NAME_MAPPINGS)
            add_scope_and_type_from_genotype(genocolorectal, record)
            mtype = record.raw_fields['moleculartestingtype']
            genocolorectal.add_molecular_testing_type_strict(TEST_TYPE_MAP_COLO[mtype.downcase.strip]) \
                           unless mtype.nil?
            genocolorectal.add_test_scope(TEST_SCOPE_MAP_COLO_COLO[mtype.downcase.strip]) \
                           unless mtype.nil?
            add_positive_teststatus(genocolorectal, record)
            failed_teststatus(genocolorectal, record)
            add_benign_varclass(genocolorectal, record)
            add_organisationcode_testresult(genocolorectal)
            res = add_gene_from_report(genocolorectal, record) # Added by Francesco
            res.map { |cur_genotype| @persister.integrate_and_store(cur_genotype) }
          end

          def add_organisationcode_testresult(genocolorectal)
            genocolorectal.attribute_map['organisationcode_testresult'] = '699C0'
          end

          def add_positive_teststatus(genocolorectal, record)
            rawgenotype = record.raw_fields['genotype']
            case rawgenotype
            when /MLPA pred negative/
              genocolorectal.add_status(1)
              @logger.debug "NEGATIVE status for : #{record.raw_fields['genotype']}"
            when /pred (other) negative/
              genocolorectal.add_status(:negative)
              @logger.debug "NEGATIVE status for : #{record.raw_fields['genotype']}"
            when /seq 1-12, MLPA normal/
              genocolorectal.add_status(:negative)
              @logger.debug "NEGATIVE status for : #{record.raw_fields['genotype']}"
            when /pred complex mut -ve/
              genocolorectal.add_status(:negative)
              @logger.debug "NEGATIVE status for : #{record.raw_fields['genotype']}"
            when /Pred seq -ve (APC)/
              genocolorectal.add_status(:negative)
              @logger.debug "NEGATIVE status for : #{record.raw_fields['genotype']}"
            when /MLPA conf -ve/
              genocolorectal.add_status(:negative)
              @logger.debug "NEGATIVE status for : #{record.raw_fields['genotype']}"
            when /MLPA -ve + Seq (unknown variant)/
              genocolorectal.add_status(:negative)
              @logger.debug "NEGATIVE status for : #{record.raw_fields['genotype']}"
            when /NGS MSH2,MLH1,MSH6 normal/
              genocolorectal.add_status(:negative)
              @logger.debug "NEGATIVE status for : #{record.raw_fields['genotype']}"
            when /No mutation identified/
              genocolorectal.add_status(:negative)
              @logger.debug "NEGATIVE status for : #{record.raw_fields['genotype']}"
            when /Pred seq MSH2 -ve/
              genocolorectal.add_status(:negative)
              @logger.debug "NEGATIVE status for : #{record.raw_fields['genotype']}"
            when /Confirmation neg/
              genocolorectal.add_status(:negative)
              @logger.debug "NEGATIVE status for : #{record.raw_fields['genotype']}"
            when /Pred MLPA EPCAM del -ve/
              genocolorectal.add_status(:negative)
              @logger.debug "NEGATIVE status for : #{record.raw_fields['genotype']}"
            else
              @logger.debug 'Cannot determine test status for : '\
                            "#{record.raw_fields['genotype']} a priori"
            end
          end

          def failed_teststatus(genocolorectal, record)
            rawgenotype = record.raw_fields['report']
            if /No results were obtained from this sample/.match(rawgenotype)
              genocolorectal.add_status(:failed)
            else
              @logger.debug 'Cannot determine test status for : '\
                            "#{record.raw_fields['report']} a priori"
            end
          end

          def add_benign_varclass(genocolorectal, record)
            rawgenotype = record.raw_fields['genotype']
            rawreport = record.raw_fields['report']
            if /Class 2/i.match(rawgenotype)
              genocolorectal.add_variant_class(2)
            elsif /benign/.match(rawgenotype)
              genocolorectal.add_variant_class(2)
            elsif /Evaluation of the available evidence suggests that this variant is 
                  likely to be benign/ix.match(rawreport)
              genocolorectal.add_variant_class(2)
            end
          end

          def add_gene_from_report(genocolorectal, record)
            genetictestscope = genocolorectal.attribute_map['genetictestscope']
            rawreport = record.raw_fields['report']
            genotypes = []
            geni = rawreport&.scan(COLORECTAL_GENES_REGEX)
            if rawreport&.scan(COLORECTAL_GENES_REGEX).nil?
              genocolorectal.add_gene_colorectal(nil)
              genocolorectal.add_protein_impact(nil)
              genocolorectal.add_gene_location(nil)
              @logger.debug "EMPTY REPORT FOR #{rawreport}"
              genotypes.append(genocolorectal)
            elsif geni.uniq.length > 1
              if PATH_TWOGENES_VARIANTS.match(rawreport)
                genocolorectal2 = genocolorectal.dup_colo
                neg_genes = geni.flatten - [PATH_TWOGENES_VARIANTS.match(rawreport)[:genes],
                                            PATH_TWOGENES_VARIANTS.match(rawreport)[:genes2]]
                neg_genes.each do |genes|
                  genocolorectal1 = genocolorectal.dup_colo
                  @logger.debug "SUCCESSFUL gene parse for negative test for: #{genes}"
                  genocolorectal1.add_status(1)
                  genocolorectal1.add_gene_colorectal(genes)
                  genocolorectal1.add_protein_impact(nil)
                  genocolorectal1.add_gene_location(nil)
                  genotypes.append(genocolorectal1)
                end
                genocolorectal.add_gene_colorectal($LAST_MATCH_INFO[:genes])
                genocolorectal.add_gene_location($LAST_MATCH_INFO[:cdna])
                genotypes.append(genocolorectal)
                genocolorectal2.add_gene_colorectal($LAST_MATCH_INFO[:genes2])
                genocolorectal2.add_gene_location($LAST_MATCH_INFO[:cdna2])
                genotypes.append(genocolorectal2)
                genotypes
              elsif record.raw_fields['genotype'] == 'FAP diagn -ve'
                rawreport.scan(COLORECTAL_GENES_REGEX).each do |genes|
                  @logger.debug "SUCCESSFUL gene parse for negative test for: #{genes}"
                  genocolorectal1 = genocolorectal.dup_colo
                  genocolorectal1.add_status(1)
                  genocolorectal1.add_gene_colorectal(genes.join)
                  genotypes << genocolorectal1
                end
              elsif record.raw_fields['genotype'] == 'MLH1 only -ve'
                if CDNA_REGEX.match(rawreport)
                  genocolorectal.add_status(1)
                  genocolorectal.add_gene_colorectal('MLH1')
                  genocolorectal.add_gene_location($LAST_MATCH_INFO[:cdna])
                  genotypes << genocolorectal
                else
                  genocolorectal.add_status(1)
                  genocolorectal.add_gene_colorectal('MLH1')
                  genotypes << genocolorectal
                end
              elsif record.raw_fields['genotype'] == 'MSH2 only -ve'
                genocolorectal.add_status(1)
                genocolorectal.add_gene_colorectal('MSH2')
                genotypes << genocolorectal
              elsif record.raw_fields['genotype'] == 'Normal'
                rawreport.scan(COLORECTAL_GENES_REGEX).each do |genes|
                  @logger.debug "SUCCESSFUL gene parse for negative test for: #{genes}"
                  genocolorectal1 = genocolorectal.dup_colo
                  genocolorectal1.add_status(1)
                  genocolorectal1.add_gene_colorectal(genes.join)
                  genotypes << genocolorectal1
                end
              elsif record.raw_fields['genotype'] == 'NGS MSH2,MLH1,MSH6 normal'
                rawreport.scan(COLORECTAL_GENES_REGEX).each do |genes|
                  @logger.debug "SUCCESSFUL gene parse for negative test for: #{genes}"
                  genocolorectal1 = genocolorectal.dup_colo
                  genocolorectal1.add_status(1)
                  genocolorectal1.add_gene_colorectal(genes.join)
                  genotypes << genocolorectal1
                end
              elsif NOPATH_REGEX.match(rawreport) ||
                    ABSENT_REGEX.match(rawreport) ||
                    /No pathogenic/.match(rawreport)
                rawreport.scan(COLORECTAL_GENES_REGEX).each do |genes|
                  @logger.debug "SUCCESSFUL gene parse for negative test for: #{genes}"
                  genocolorectal1 = genocolorectal.dup_colo
                  genocolorectal1.add_status(1)
                  genocolorectal1.add_gene_colorectal(genes.join)
                  genotypes << genocolorectal1
                end
              elsif PATHVAR_EXONS_REGEX.match(rawreport)
                neg_genes = geni - [[PATHVAR_EXONS_REGEX.match(rawreport)[:genes]]]
                neg_genes.each do |genes|
                  genocolorectal1 = genocolorectal.dup_colo
                  @logger.debug "SUCCESSFUL gene parse for negative EXONIC test for: #{genes}"
                  genocolorectal1.add_status(1)
                  genocolorectal1.add_gene_colorectal(genes.join)
                  genocolorectal1.add_protein_impact(nil)
                  genocolorectal1.add_gene_location(nil)
                  genotypes.append(genocolorectal1)
                end
                genocolorectal.add_gene_colorectal($LAST_MATCH_INFO[:genes])
                genocolorectal.add_exon_location($LAST_MATCH_INFO[:exons].delete(' '))
                genocolorectal.add_variant_type(rawreport)
                @logger.debug "SUCCESSFUL gene parse for: #{$LAST_MATCH_INFO[:genes]}"
                @logger.debug "SUCCESSFUL cdna change parse for: #{$LAST_MATCH_INFO[:exons]}"
                genotypes.append(genocolorectal)
              elsif PATHVAR_REGEX.match(rawreport)
                neg_genes = geni - [[PATHVAR_REGEX.match(rawreport)[:genes]]]
                neg_genes.each do |genes|
                  genocolorectal1 = genocolorectal.dup_colo
                  @logger.debug "SUCCESSFUL gene parse for negative test for: #{genes}"
                  genocolorectal1.add_status(1)
                  genocolorectal1.add_gene_colorectal(genes.join)
                  genocolorectal1.add_protein_impact(nil)
                  genocolorectal1.add_gene_location(nil)
                  genotypes.append(genocolorectal1)
                end
                genocolorectal.add_gene_colorectal($LAST_MATCH_INFO[:genes])
                genocolorectal.add_protein_impact($LAST_MATCH_INFO[:impact])
                genocolorectal.add_gene_location($LAST_MATCH_INFO[:cdna])
                @logger.debug "SUCCESSFUL gene parse for: #{$LAST_MATCH_INFO[:genes]}"
                @logger.debug "SUCCESSFUL cdna change parse for: #{$LAST_MATCH_INFO[:cdna]}"
                @logger.debug "SUCCESSFUL protein impact parse for: #{$LAST_MATCH_INFO[:impact]}"
                genotypes.append(genocolorectal)
              elsif PATHVAR_REGEX2.match(rawreport)
                neg_genes = geni - [[PATHVAR_REGEX2.match(rawreport)[:genes]]]
                neg_genes.each do |genes|
                  genocolorectal1 = genocolorectal.dup_colo
                  @logger.debug "SUCCESSFUL gene parse for negative test for: #{genes}"
                  genocolorectal1.add_status(1)
                  genocolorectal1.add_gene_colorectal(genes.join)
                  genocolorectal1.add_protein_impact(nil)
                  genocolorectal1.add_gene_location(nil)
                  genotypes.append(genocolorectal1)
                end
                genocolorectal.add_gene_colorectal($LAST_MATCH_INFO[:genes])
                genocolorectal.add_protein_impact($LAST_MATCH_INFO[:impact])
                genocolorectal.add_gene_location($LAST_MATCH_INFO[:cdna])
                @logger.debug "SUCCESSFUL gene parse for: #{$LAST_MATCH_INFO[:genes]}"
                @logger.debug "SUCCESSFUL cdna change parse for: #{$LAST_MATCH_INFO[:cdna]}"
                @logger.debug "SUCCESSFUL protein impact parse for: #{$LAST_MATCH_INFO[:impact]}"
                genotypes.append(genocolorectal)
              elsif PATHVAR_TWOGENES_REGEX.match(rawreport) &&
                    (ABSENT_REGEX.match(rawreport) || NOPATH_REGEX.match(rawreport) ||
                    NOPATH_SINGLEGENE.match(rawreport)) && PATHVAR_REGEX.match(rawreport)
                genocolorectal2 = genocolorectal.dup_colo
                neg_genes = geni - [[PATHVAR_REGEX.match(rawreport)[:genes]]]
                neg_genes.each do |genes|
                  genocolorectal1 = genocolorectal.dup_colo
                  @logger.debug "SUCCESSFUL gene parse for negative test for: #{genes}"
                  genocolorectal1.add_status(1)
                  genocolorectal1.add_gene_colorectal(genes.join)
                  genocolorectal1.add_protein_impact(nil)
                  genocolorectal1.add_gene_location(nil)
                  genotypes.append(genocolorectal1)
                end
                genocolorectal.add_status(1)
                genocolorectal.add_gene_colorectal($LAST_MATCH_INFO[:genes])
                genocolorectal.add_protein_impact($LAST_MATCH_INFO[:impact])
                genocolorectal.add_gene_location($LAST_MATCH_INFO[:cdna])
                genotypes.append(genocolorectal)
                genocolorectal2.add_status(1)
                genocolorectal2.add_gene_colorectal($LAST_MATCH_INFO[:genes])
                genocolorectal2.add_protein_impact($LAST_MATCH_INFO[:impact2])
                genocolorectal2.add_gene_location($LAST_MATCH_INFO[:cdna2])
                genotypes.append(genocolorectal2)
                # genotypes
                @logger.debug "NEGATIVE RESULTS FOR MULTIPLE LIST IDOUBLE GENE VARIANT #{rawreport}"
              elsif EXON_ALTERNATIVE_REGEX.match(rawreport)
                neg_genes = geni - [[EXON_ALTERNATIVE_REGEX.match(rawreport)[:genes]]]
                neg_genes.each do |genes|
                  genocolorectal1 = genocolorectal.dup_colo
                  @logger.debug 'SUCCESSFUL gene parse for negative test for: '\
                                "#{EXON_ALTERNATIVE_REGEX.match(rawreport)[:genes]}"
                  genocolorectal1.add_status(1)
                  genocolorectal1.add_gene_colorectal(genes.join)
                  genocolorectal1.add_protein_impact(nil)
                  genocolorectal1.add_gene_location(nil)
                  genotypes.append(genocolorectal1)
                end
                genocolorectal.add_gene_colorectal(EXON_ALTERNATIVE_REGEX.match(rawreport)[:genes])
                genocolorectal.add_exon_location(EXON_ALTERNATIVE_REGEX.match(rawreport)[:exons])
                @logger.debug 'SUCCESSFUL gene parse for: '\
                              "#{EXON_ALTERNATIVE_REGEX.match(rawreport)[:genes]}"
                genotypes.append(genocolorectal)
              elsif PATHVAR_TWOGENES_REGEX.match(rawreport)
                genocolorectal2 = genocolorectal.dup_colo
                neg_genes = geni - [[PATHVAR_REGEX.match(rawreport)[:genes]]]
                neg_genes.each do |genes|
                  genocolorectal1 = genocolorectal.dup_colo
                  @logger.debug "SUCCESSFUL gene parse for negative test for: #{genes}"
                  genocolorectal1.add_status(1)
                  genocolorectal1.add_gene_colorectal(genes.join)
                  genocolorectal1.add_protein_impact(nil)
                  genocolorectal1.add_gene_location(nil)
                  genotypes.append(genocolorectal1)
                end
                genocolorectal.add_gene_colorectal($LAST_MATCH_INFO[:genes])
                genocolorectal.add_protein_impact($LAST_MATCH_INFO[:impact])
                genocolorectal.add_gene_location($LAST_MATCH_INFO[:cdna])
                genotypes.append(genocolorectal)
                genocolorectal2.add_gene_colorectal($LAST_MATCH_INFO[:genes])
                genocolorectal2.add_protein_impact($LAST_MATCH_INFO[:impact2])
                genocolorectal2.add_gene_location($LAST_MATCH_INFO[:cdna2])
                genotypes.append(genocolorectal2)
                @logger.debug "MULTIPLE LIST IDOUBLE GENE VARIANT #{rawreport}"
              end
              genotypes
            elsif PATHVAR_TWOGENES_REGEX.match(rawreport)
              genocolorectal1 = genocolorectal.dup_colo
              genocolorectal.add_gene_colorectal($LAST_MATCH_INFO[:genes])
              genocolorectal.add_protein_impact($LAST_MATCH_INFO[:impact])
              genocolorectal.add_gene_location($LAST_MATCH_INFO[:cdna])
              genotypes.append(genocolorectal)
              genocolorectal1.add_gene_colorectal($LAST_MATCH_INFO[:genes])
              genocolorectal1.add_protein_impact($LAST_MATCH_INFO[:impact2])
              genocolorectal1.add_gene_location($LAST_MATCH_INFO[:cdna2])
              genotypes.append(genocolorectal1)
              @logger.debug "DOUBLE GENE #{rawreport}"
            elsif geni.uniq.length == 1
              if record.raw_fields['genotype'] == 'Pred seq -ve (APC)'
                genocolorectal.add_gene_colorectal(COLORECTAL_GENES_REGEX.match(rawreport)[0])
                genocolorectal.add_status(1)
                genotypes.append(genocolorectal)
              elsif record.raw_fields['genotype'] == 'Pred seq MSH2 -ve'
                genocolorectal.add_gene_colorectal(COLORECTAL_GENES_REGEX.match(rawreport)[0])
                genocolorectal.add_status(1)
                genotypes.append(genocolorectal)
              elsif record.raw_fields['genotype'] == 'MLPA conf -ve'
                genocolorectal.add_gene_colorectal(COLORECTAL_GENES_REGEX.match(rawreport)[0])
                genocolorectal.add_status(1)
                genotypes.append(genocolorectal)
              elsif record.raw_fields['genotype'] == 'Seq pred negative'
                genocolorectal.add_gene_colorectal(COLORECTAL_GENES_REGEX.match(rawreport)[0])
                genocolorectal.add_status(1)
                genotypes.append(genocolorectal)
              elsif record.raw_fields['genotype'] == 'pred (other) negative'
                genocolorectal.add_gene_colorectal(COLORECTAL_GENES_REGEX.match(rawreport)[0])
                genocolorectal.add_status(1)
                genotypes.append(genocolorectal)
              elsif record.raw_fields['genotype'] == 'conf seq -ve'
                genocolorectal.add_gene_colorectal(COLORECTAL_GENES_REGEX.match(rawreport)[0])
                genocolorectal.add_status(1)
                genotypes.append(genocolorectal)
              elsif record.raw_fields['genotype'] == 'pred complex mut -ve'
                genocolorectal.add_gene_colorectal(COLORECTAL_GENES_REGEX.match(rawreport)[0])
                genocolorectal.add_status(1)
                genotypes.append(genocolorectal)
              elsif record.raw_fields['genotype'] == 'Pred MLPA EPCAM del -ve'
                genocolorectal.add_gene_colorectal(COLORECTAL_GENES_REGEX.match(rawreport)[0])
                genocolorectal.add_status(1)
                genotypes.append(genocolorectal)
              elsif record.raw_fields['genotype'] == 'FAP pred -ve (APC)'
                genocolorectal.add_gene_colorectal(COLORECTAL_GENES_REGEX.match(rawreport)[0])
                genocolorectal.add_status(1)
                genotypes.append(genocolorectal)
              elsif record.raw_fields['genotype'] == 'Diagnostic APC -ve'
                genocolorectal.add_gene_colorectal(COLORECTAL_GENES_REGEX.match(rawreport)[0])
                genocolorectal.add_status(1)
                genotypes.append(genocolorectal)
              elsif record.raw_fields['genotype'] == 'Seq/MLPA_diagnostic_negative'
                genocolorectal.add_gene_colorectal(COLORECTAL_GENES_REGEX.match(rawreport)[0])
                genocolorectal.add_status(1)
                genotypes.append(genocolorectal)
              elsif record.raw_fields['genotype'] == 'MLH1 only -ve'
                genocolorectal.add_gene_colorectal(COLORECTAL_GENES_REGEX.match(rawreport)[0])
                genocolorectal.add_status(1)
                genotypes.append(genocolorectal)
              elsif record.raw_fields['genotype'] == 'No mutation identified'
                genocolorectal.add_gene_colorectal(COLORECTAL_GENES_REGEX.match(rawreport)[0])
                genocolorectal.add_status(1)
                genotypes.append(genocolorectal)
              elsif (ABSENT_REGEX.match(rawreport) || NOPATH_REGEX.match(rawreport) ||
                    NOPATH_SINGLEGENE.match(rawreport) || /No pathogenic/.match(rawreport)) &&
                    PATHVAR_REGEX.match(rawreport)
                if genetictestscope == 'Full screen Colorectal Lynch or MMR'
                  genocolorectal.add_gene_colorectal($LAST_MATCH_INFO[:genes])
                  genocolorectal.add_protein_impact($LAST_MATCH_INFO[:impact])
                  genocolorectal.add_gene_location($LAST_MATCH_INFO[:cdna])
                  genocolorectal.add_status(1)
                  @logger.debug "SUCCESSFUL gene parse for: #{$LAST_MATCH_INFO[:genes]}"
                  @logger.debug "SUCCESSFUL cdna change parse for: #{$LAST_MATCH_INFO[:cdna]}"
                  @logger.debug "SUCCESSFUL protein impact parse for: #{$LAST_MATCH_INFO[:impact]}"
                  @logger.debug "FOUND ABSENT VARIANT FOR : #{rawreport}"
                  genotypes << genocolorectal
                elsif genetictestscope == 'Targeted Colorectal Lynch or MMR'
                  genocolorectal.add_gene_colorectal($LAST_MATCH_INFO[:genes])
                  genocolorectal.add_protein_impact(nil)
                  genocolorectal.add_gene_location(nil)
                  genocolorectal.add_status(1)
                  @logger.debug "SUCCESSFUL gene parse for: #{$LAST_MATCH_INFO[:genes]}"
                  @logger.debug "FOUND ABSENT VARIANT FOR : #{rawreport}"
                  genotypes << genocolorectal
                end
              elsif ABSENT_REGEX.match(rawreport) ||
                    NOPATH_REGEX.match(rawreport) ||
                    NOPATH_SINGLEGENE.match(rawreport) ||
                    /No pathogenic/.match(rawreport)
                genocolorectal.add_gene_colorectal(COLORECTAL_GENES_REGEX.match(rawreport)[0])
                genocolorectal.add_status(1)
                @logger.debug "SUCCESSFUL gene parse for: #{COLORECTAL_GENES_REGEX.match(rawreport)[0]}"
                @logger.debug "FOUND ABSENT VARIANT FOR : #{rawreport}"
                genotypes << genocolorectal
              elsif PATHVAR_REGEX.match(rawreport)
                genocolorectal.add_gene_colorectal($LAST_MATCH_INFO[:genes])
                genocolorectal.add_protein_impact($LAST_MATCH_INFO[:impact])
                genocolorectal.add_gene_location($LAST_MATCH_INFO[:cdna])
                @logger.debug "SUCCESSFUL gene parse for: #{$LAST_MATCH_INFO[:genes]}"
                @logger.debug "SUCCESSFUL cdna change parse for: #{$LAST_MATCH_INFO[:cdna]}"
                @logger.debug "SUCCESSFUL protein impact parse for: #{$LAST_MATCH_INFO[:impact]}"
                genotypes << genocolorectal
              elsif PATHVAR_REGEX2.match(rawreport)
                genocolorectal.add_gene_colorectal($LAST_MATCH_INFO[:genes])
                genocolorectal.add_protein_impact($LAST_MATCH_INFO[:impact])
                genocolorectal.add_gene_location($LAST_MATCH_INFO[:cdna])
                @logger.debug "SUCCESSFUL gene parse for: #{$LAST_MATCH_INFO[:genes]}"
                @logger.debug "SUCCESSFUL cdna change parse for: #{$LAST_MATCH_INFO[:cdna]}"
                @logger.debug "SUCCESSFUL protein impact parse for: #{$LAST_MATCH_INFO[:impact]}"
                genotypes << genocolorectal
              elsif PATHVAR_BIGINDELS.match(rawreport)
                genocolorectal.add_gene_colorectal($LAST_MATCH_INFO[:genes])
                genocolorectal.add_gene_location($LAST_MATCH_INFO[:cdna])
                @logger.debug "SUCCESSFUL gene parse for: #{$LAST_MATCH_INFO[:genes]}"
                @logger.debug "SUCCESSFUL cdna change parse for: #{$LAST_MATCH_INFO[:cdna]}"
                genotypes << genocolorectal
              elsif  COLORECTAL_GENES_REGEX.match(rawreport) &&
                     EXON_LOCATION_REGEX.match(rawreport) &&
                     NOMUT_REGEX.match(rawreport)
                if genetictestscope == 'Full screen Colorectal Lynch or MMR'
                  genocolorectal.add_gene_colorectal(COLORECTAL_GENES_REGEX.match(rawreport)[0])
                  genocolorectal.add_exon_location(EXON_LOCATION_REGEX.match(rawreport)[1].delete(' '))
                  genocolorectal.add_variant_type(rawreport)
                  genocolorectal.add_status(1)
                  genotypes.append(genocolorectal)
                elsif genetictestscope == 'Targeted Colorectal Lynch or MMR'
                  genocolorectal.add_gene_colorectal(COLORECTAL_GENES_REGEX.match(rawreport)[0])
                  genocolorectal.add_exon_location(nil)
                  genocolorectal.add_variant_type(nil)
                  genocolorectal.add_status(1)
                  genotypes.append(genocolorectal)
                end
              elsif COLORECTAL_GENES_REGEX.match(rawreport) &&
                    EXON_LOCATION_REGEX.match(rawreport) &&
                    NO_DEL_REGEX.match(rawreport)
                if genetictestscope == 'Full screen Colorectal Lynch or MMR'
                  genocolorectal.add_gene_colorectal(COLORECTAL_GENES_REGEX.match(rawreport)[0])
                  genocolorectal.add_exon_location(EXON_LOCATION_REGEX.match(rawreport)[1].delete(' '))
                  genocolorectal.add_variant_type(rawreport)
                  genocolorectal.add_status(1)
                  genotypes.append(genocolorectal)
                elsif genetictestscope == 'Targeted Colorectal Lynch or MMR'
                  genocolorectal.add_gene_colorectal(COLORECTAL_GENES_REGEX.match(rawreport)[0])
                  genocolorectal.add_exon_location(nil)
                  genocolorectal.add_variant_type(nil)
                  genocolorectal.add_status(1)
                  genotypes.append(genocolorectal)
                end
              elsif ABSENT_REGEX.match(rawreport) && COLORECTAL_GENES_REGEX.match(rawreport)
                genocolorectal.add_gene_colorectal(COLORECTAL_GENES_REGEX.match(rawreport)[0])
                genocolorectal.add_status(1)
                genotypes.append(genocolorectal)
                @logger.debug "ABSENT MUTATION  #{rawreport}"
              elsif COLORECTAL_GENES_REGEX.match(rawreport) && EXON_LOCATION_REGEX.match(rawreport)
                genocolorectal.add_gene_colorectal(COLORECTAL_GENES_REGEX.match(rawreport)[0])
                genocolorectal.add_exon_location(EXON_LOCATION_REGEX.match(rawreport)[1].delete(' '))
                genocolorectal.add_variant_type(rawreport)
                genotypes.append(genocolorectal)
              elsif /No pathogenic variant/i.match(rawreport) && COLORECTAL_GENES_REGEX.match(rawreport)
                genocolorectal.add_gene_colorectal($LAST_MATCH_INFO[:colorectal])
                genocolorectal.add_status(1)
                @logger.debug "SUCCESSFUL gene parse for: #{$LAST_MATCH_INFO[:colorectal]}"
                @logger.debug "FOUND ABSENT VARIANT FOR : #{rawreport}"
                genotypes << genocolorectal
              else
                @logger.debug "UNKNOWN SINGLE GENE GENOTYPE: #{rawreport}"
                genocolorectal.add_gene_colorectal(COLORECTAL_GENES_REGEX.match(rawreport)[0])
              end
              genotypes
            else
              @logger.debug "UNKNOWN GENOTYPE for  #{rawreport}"
              genocolorectal.add_gene_colorectal(nil)
              genocolorectal.add_protein_impact(nil)
              genocolorectal.add_gene_location(nil)
              genotypes << genocolorectal
            end
            genotypes
          end

          def add_scope_and_type_from_genotype(genocolorectal, record)
            Maybe(record.raw_fields['genotype']).each do |typescopegeno|
              genocolorectal.add_molecular_testing_type_strict(TEST_TYPE_MAP_COLO[typescopegeno])
              scope = TEST_SCOPE_MAP_COLO_COLO[typescopegeno]
              genocolorectal.add_test_scope(scope) if scope
            end
          end

          def process_scope(geno, genocolorectal, record)
            scope = Maybe(record.raw_fields['reason']).
                    or_else(Maybe(record.mapped_fields['genetictestscope']).or_else(''))
            # ------------ Set the test scope ---------------------
            if (geno.downcase.include? 'ashkenazi') || (geno.include? 'AJ')
              genocolorectal.add_test_scope(:aj_screen)
            else
              stripped_scope = TEST_SCOPE_MAP_COLO_COLO[scope.downcase.strip]
              genocolorectal.add_test_scope(stripped_scope) if stripped_scope
            end
          end

          def add_colorectal_from_raw_genotype(genocolorectal, record)
            colo_string = record.raw_fields['genotype']
            if colo_string.scan(COLORECTAL_GENES_REGEX).size > 1
              @logger.error "Multiple genes detected in report: #{colo_string};"
            elsif COLORECTAL_GENES_REGEX.match(colo_string) &&
                  colo_string.scan(COLORECTAL_GENES_REGEX).size == 1
              genocolorectal.add_gene_colorectal($LAST_MATCH_INFO[:colorectal])
              # when COLORECTAL_GENES_REGEX and test_string.scan(GENE_REGEX).size > 1
              @logger.debug "SUCCESSFUL gene parse from raw_record for: #{$LAST_MATCH_INFO[:colorectal]}"
            else
              @logger.debug 'No Gene detected'
            end
          end

          def process_exons(genotype_string, genocolorectal)
            exon_matches = EXON_LOCATION_REGEX.match(genotype_string)
            if exon_matches
              genocolorectal.add_exon_location(exon_matches[1].delete(' '))
              genocolorectal.add_variant_type(genotype_string)
              @logger.debug "SUCCESSFUL exon extraction for: #{genotype_string}"
            else
              @logger.warn "Cannot extract exon from: #{genotype_string}"
            end
          end

          def finalize
            @extractor.summary
            super
          end
        end
        # rubocop:enable Metrics/ClassLength
      end
    end
  end
end

