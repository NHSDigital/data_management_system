module Import
  module Helpers
    module Colorectal
      module Providers
        module Rr8
          # Constants used by Leeds Colorectal
          module Constants
            TEST_SCOPE_MAP_COLO = { 'carrier test' => :targeted_mutation,
                                    'confirmation' => :targeted_mutation,
                                    'diagnostic' =>:full_screen,
                                    'diagnostic; fap' => :full_screen,
                                    'diagnostic; lynch' => :full_screen,
                                    'diagnostic; pms2' => :full_screen,
                                    'predictive' => :targeted_mutation,
                                    'predictive test' => :targeted_mutation,
                                    'r209.1' => :full_screen,
                                    'r209.2' => :full_screen,
                                    'r210.5' => :full_screen,
                                    'r210.2' => :full_screen,
                                    'r211.1' => :full_screen,
                                    'r211.2' => :full_screen,
                                    'familial' => :targeted_mutation }.freeze

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
                                    
            GENES = 'APC|ATM|BAP1|BMPR1A|BRCA1|BRCA2|CHEK2|EPCAM|FH|FLCN|GREM1|MET|
                     MLH1|MSH2|MSH6|MUTYH|NTHL1|PALB2|PMS2|POLD1|POLE|PTEN|RAD51C|RAD51D|
                     RNF43|SDHB|SMAD4|STK11|TP53|VHL'

            CDNA_REGEX = /c\.(?<cdna>[\w+>*\-]+)?/ix
            PROTEIN_REGEX = /\(?p\.\(?(?<impact>\w+)\)?/ix
            EXON_REGEX = /(?<exon>exon(s)?[\s\-\d]+)/ix
            GENE_FAIL_REGEX= /(?=(?<gene>#{GENES})[\w\s]+fail)/ix
            
            GENE_FIRST_VARIANT_REGEX = /((?<genes>#{GENES})[\w\s]+
                                        ((?<exons>exon(s)?[\w\s\d]+)|(c\.(?<cdna>[\w+>*\-\(\)\.\s]+)?)))/ix
                                        
            VARIANT_FIRST_GENE_REGEX = /(((?<exons>exon(s)?[\w\s\d]+)|(c\.(?<cdna>[\w+>*\-\(\)\.\s]+)?))
                                        [\w\s]+(?<genes>#{GENES}))/ix
                                        
            TESTSTATUS_REGEX = /unaffected|neg|normal/i .freeze
            NOPATH_REGEX = /.No pathogenic variant was identified./i .freeze
            EXON_VARIANT_REGEX = /(?<variant>del|dup|ins).+ex(on)?s?\s?
                                  (?<exons>[0-9]+(-[0-9]+)?)|
                                  ex(on)?s?\s?(?<exons>[0-9]+(-[0-9]+)?)\s?
                                  (?<variant>del|dup|ins)|
                                  ex(on)?s?\s?(?<exons>[0-9]+\s?(\s?-\s?[0-9]+)?)\s?
                                  (?<variant>del|dup|ins)?|
                                  (?<variant>del|dup|ins)\s?(?<exons>[0-9]+(?<dgs>-[0-9]+)?)|
                                  ex(on)?s?\s?(?<exons>[0-9]+(\sto\s[0-9]+)?)\s
                                  (?<variant>del|dup|ins)|
                                  x(?<exons>[0-9+-? ]+)+(?<variant>del|dup|ins)/ix


            COLORECTAL_GENES_REGEX = /(?<colorectal>#{GENES})/x.freeze
                                      
            VARIANT_REPORT_REGEX = /(?<report>(hetero|homo)zygo[\w\s\-.>():=,'+]+)+/ix
            
            EXONIC_REPORT_REGEX = /(?<report>(#{GENES})\sexon(s)?[\w\s\-.>():=,&]+)/ix
            
            PATHOGENIC_REPORT_REGEX = /(?<report>pathogenic\s(MLH1|MSH2|APC)[\w\s\-.>():=,&]+)/ix
            
            TARG_GENE_REGEX = /(?<report>(#{GENES})[\w\s]+(c\.[\w\s\-.>():=,']+))/ix
            
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
                                   (?<genes2>APC|BMPR1A|EPCAM|MLH1|MSH2|MSH6|MUTYH|PMS2|POLD1|POLE|
                                   PTEN|SMAD4|STK11|GREM1|NTHL1)[\s\w]{2,}
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
                                      
         PATHOGENIC_REGEX = /(?<pathogenic>likely\spathogenic|pathogenic)/i.freeze
          
          GENES_FILEPATH = 'lib/import/helpers/colorectal/providers/rr8/genes.yml'.freeze
          STATUS_FILEPATH = 'lib/import/helpers/colorectal/providers/rr8/status.yml'.freeze
            
          GENES_PANEL = {
            'apc' => %w[APC],
            'epcam' => %w[EPCAM],
            'mlh1' => %w[MLH1],
            'mlh1_msh2' => %w[MLH1 MSH2],
            'mlh1_msh2_msh6' => %w[MLH1 MSH2 MSH6],
            'mlh1_pms2' => %w[MLH1 PMS2],
            'msh2' => %w[MSH2],
            'msh6' => %w[MSH6],
            'mutyh' => %w[MUTYH],
            'pms2' => %w[PMS2]
          }
          
          STATUS_PANEL = {
            'unknown' => 4,
            'normal' => 1,
            'abnormal' => 2,
            'normal_var' => 10,
            'fail' => 9
          }
          
          VARIANT_CLASS_5 =[
           'conf mlpa +ve',
           'mlh1 confirmation +ve',
           'mlpa del confirmation +ve',
           'msh2 confirmation +ve',
           'mlpa +ve(large exon deletion) + seq -ve',
           'mlpa multi-exon deletion (with seq)',
           'ngs class m',
           'sequencing positive',
           'pred mlpa epcam del +ve',
           'pred mlpa msh2 del +ve',
           'pred mlpa msh2 dup +ve',
           'pred mlpa msh6 del +ve',
           'pred seq mlh1 +ve',
           'pred seq msh2 +ve',
           'pred seq msh6 +ve',
           'confirmation_seq_positive',
           'diagnostic apc +ve',
           'predictive_seq_positive',
           'seq mutation +ve',
           'biallelic pred positive',
           'mlpa pred positive',
           'pred complex mut +ve',
           'r802x homozygote (diag)',
           'seq pred positive',
           'apc - conf mlpa +ve',
           'fap diagn mutyh het.',
           'conf seq +ve (apc)',
           'conf seq +ve (mutyh)',
           'fap conf-pred +ve (apc)',
           'fap diagn +ve (apc)',
           'fap diagn +ve (mutyh c.het)',
           'fap diagn +ve (mutyh homoz)',
           'fap diagn mutyh het.',
           '(v2) mutyh het.',
           'apc - conf seq +ve'
         ]
          end
        end
      end
    end
  end
end