module Import
  module Helpers
    module Colorectal
      module Providers
        module Rr8
          # Constants used by Leeds Colorectal
          module Constants
            TEST_SCOPE_MAP_COLO = { 'carrier test' => :targeted_mutation,
                                    'confirmation' => :targeted_mutation,
                                    'diagnostic' => :full_screen,
                                    'diagnostic; fap' => :full_screen,
                                    'diagnostic; lynch' => :full_screen,
                                    'diagnostic; pms2' => :full_screen,
                                    'predictive' => :targeted_mutation,
                                    'predictive test' => :targeted_mutation,
                                    'r209.1' => :full_screen,
                                    'r209.2' => :full_screen,
                                    'r210.5' => :full_screen,
                                    'r210.1' => :full_screen,
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
                                   'familial' => :predictive }.freeze

            PASS_THROUGH_FIELDS = %w[age consultantcode
                                     providercode
                                     receiveddate
                                     authoriseddate
                                     requesteddate
                                     servicereportidentifier
                                     organisationcode_testresult
                                     specimentype].freeze
            FIELD_NAME_MAPPINGS = { 'consultantcode'  => 'practitionercode',
                                    'instigated_date' => 'requesteddate' }.freeze

            GENES = 'APC|ATM|BAP1|BMPR1A|BRCA1|BRCA2|CHEK2|EPCAM|FH|FLCN|GREM1|MET|
                     MLH1|MSH2|MSH6|MUTYH|NTHL1|PALB2|PMS2|POLD1|POLE|PTEN|RAD51C|RAD51D|
                     RNF43|SDHB|SMAD4|STK11|TP53|VHL'.freeze

            # rubocop:disable Lint/MixedRegexpCaptureTypes
            MMR_GENE_REGEX = /APC|BMPR1A|EPCAM|GREM1|MLH1|MSH2|MSH6|MUTYH|NTHL1|PMS2|POLD1|
                              POLE|PTEN|SMAD4|STK11/ix
            CDNA_REGEX = /c\.(?<cdna>[\w+>*\-]+)?/ix
            PROTEIN_REGEX = /\(?p\.\(?(?<impact>\w+)\)?/ix
            EXON_REGEX = /(?<exon>exon(s)?[\s\-\d]+)/ix
            GENE_FAIL_REGEX = /(?=(?<gene>#{GENES})[\w\s]+fail)/ix
            NOPATH_REGEX = /.No pathogenic variant was identified./i
            EXON_VARIANT_REGEX = /(?<variant>del|dup|ins).+ex(on)?s?\s?
                                  (?<exons>[0-9]+(-[0-9]+)?)|
                                  ex(on)?s?\s?(?<exons>[0-9]+(-[0-9]+)?)\s?
                                  (?<variant>del|dup|ins)|
                                  ex(on)?s?\s?(?<exons>[0-9]+\s?(\s?-\s?[0-9]+)?)\s?
                                  (?<variant>del|dup|ins)?|
                                  (?<variant>del|dup|ins)\s?(?<exons>[0-9]+(?<dgs>-[0-9]+)?)|
                                  ex(on)?s?\s?(?<exons>[0-9]+(\sto\s[0-9]+)?)\s
                                  (?<variant>del|dup|ins)|
                                  x(?<exons>[0-9+-? ]+)+(?<variant>del|dup|ins)|
                                  ex(on)?s?[\s\w,]+(?<variant>del|dup|ins)|
                                  (?<variant>del|dup|ins)[\s\w]+gene/ix

            COLORECTAL_GENES_REGEX = /(?<colorectal>#{GENES})/x

            VARIANT_REPORT_REGEX = /(?<report>(hetero|homo)zygo[\w\s\-.>():=,'+]+)+/ix

            EXONIC_REPORT_REGEX = /(?<report>(#{GENES})\sexon(s)?[\w\s\-.>():=,&]+)/ix

            PATHOGENIC_REPORT_REGEX = /(?<report>pathogenic\s(#{GENES})[\w\s\-.>():=,&]+)/ix

            TARG_GENE_REGEX = /(?<report>(#{GENES})[\w\s]+(c\.[\w\s\-.>():=,']+))/ix

            ABSENT_REGEX = /is absent in this patient/i
            NO_DEL_REGEX = /this patient does not have the deletion/i
            PATHOGENIC_REGEX = /(?<pathogenic>likely\snon-pathogenic|likely\spathogenic|
            likely\s(to\sbe\s)?pathogenic|pathogenic[^ity]|benign|likely\s(to\sbe\s)?benign|
            uncertain\s(clinical\s)?significance)/ix
            PATHOGENIC_GENES_REGEX = /(?<pathogenic>likely\snon-pathogenic|likely\spathogenic|
            pathogenic[^ity]|benign|likely\s(to\sbe\s)?benign|
            uncertain\s(clinical\s)?significance)[\w\s\W]*(?<assocgene>#{GENES})/ix
            GENE_PATH_REGEX = /(?<assocgene>#{GENES})[\w\s\W]*(?<pathogenic>likely\snon-pathogenic|
            likely\spathogenic|pathogenic[^ity]|benign|likely\s(to\sbe\s)?benign|
            uncertain\s(clinical\s)?significance)/ix
            # rubocop:enable Lint/MixedRegexpCaptureTypes

            GENES_FILEPATH = 'lib/import/helpers/colorectal/providers/rr8/genes.yml'.freeze
            STATUS_FILEPATH = 'lib/import/helpers/colorectal/providers/rr8/status.yml'.freeze

            GENES_PANEL = {
              'apc' => %w[APC],
              'epcam' => %w[EPCAM],
              'mlh1' => %w[MLH1],
              'mlh1_msh2' => %w[MLH1 MSH2],
              'mlh1_msh2_msh6' => %w[MLH1 MSH2 MSH6],
              'mlh1_pms2' => %w[MLH1 PMS2],
              'pms2_mutyh' => %w[MUTYH PMS2],
              'msh2' => %w[MSH2],
              'msh6' => %w[MSH6],
              'mutyh' => %w[MUTYH],
              'pms2' => %w[PMS2]
            }.freeze

            STATUS_PANEL = {
              'unknown' => 4,
              'normal' => 1,
              'abnormal' => 2,
              'normal_var' => 10,
              'fail' => 9
            }.freeze

            VARIANT_CLASS_5 = [
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
            ].freeze

            VARIANT_CLASS_7 = [
              'conf seq +ve',
              'mlpa -ve + seq (splice site mutation)',
              'mlpa -ve + seq +ve (nonsense/frameshift)',
              'ngs mlh1 truncating/frameshift',
              'ngs msh2 truncating/frameshift',
              'ngs multiple exon mlpa del',
              'pred mlpa +ve',
              'mlpa positive',
              'mlpa positive (diag)',
              'pred (other) positive',
              'generic c4/5',
              'lynch diag; c4/5',
              'generic c4/5',
              'lynch diag; c4/5',
              'r210_c4/5',
              'lynch diag; c4/5',
              'generic c4/5'
            ].freeze

            NON_PATH_VARCLASS = [
              'likely benign',
              'likely to be benign',
              'non-pathological variant',
              'likely non-pathogenic',
              'benign'
            ].freeze

            EXCLUDE_STATEMENTS = [
              'Screening for mutations in MLH1, MSH2 and MSH6 is now in progress as requested.',
              'MLPA and MSH2 analysis was not requested.',
              'MLPA and MSH2 analysis were not requested.',
              'if MSH2 and MSH6 data analysis is required.',
              'No further screening for mutations in MLH1, MSH2 or MSH6 has been performed.',
              'developing further MSH2-related cancers',
              'developing MSH2-associated cancer'
            ].freeze
          end
        end
      end
    end
  end
end
