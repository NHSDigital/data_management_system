module Import
  module Helpers
    module Brca
      module Providers
        module Rcu
          module RcuConstants
            TEST_TYPE_MAPPING = { 'Diagnostic testing' => :diagnostic,
                                  'Further sample for diagnostic testing' => :diagnostic,
                                  'Confirmation of Familial Mutation' => :diagnostic,
                                  'Confirmation of Research Result' => :diagnostic,
                                  'Diagnostic testing for known mutation' => :diagnostic,
                                  'Predictive testing' => :predictive,
                                  'Family Studies' => :predictive,
                                  'Carrier testing' => :carrier }.freeze

            GENETICTESTSCOPE_METHOD_MAPPING = {
              'BRCA1 and 2 familial mutation' => :process_scope_familial_mutation,
              'BRCA1 and 2 gene analysis' => :process_scope_gene_analysis,
              'Breast & Ovarian cancer panel' => :process_scope_ovarian_panel,
              'Breast Ovarian & Colorectal cancer panel' => :process_scope_colo_ovarian_panel,
              'R205 :: Inherited breast cancer'\
              ' (without ovarian cancer) at very high familial risk' => :process_scope_r205,
              'R206 :: Inherited breast cancer'\
              ' and ovarian cancer at high familial risk levels' => :process_scope_r206,
              'R207 :: Inherited ovarian cancer (without breast cancer)' => :process_scope_r207,
              'R208 :: BRCA1 and BRCA2 testing at high familial risk' => :process_scope_r208,
              'R208 :: Inherited breast cancer and ovarian cancer' => :process_scope_r208,
              'R240 - Familial Diagnostic testing - Hered Cancers' => :process_scope_r240,
              'R242 - Predictive testing - Hered Cancers' => :process_scope_r242
            }.freeze

            BRCA_FAMILIAL_GENE_MAPPING = {
              'BRCA1 gene MLPA' => %w[BRCA1],
              'BRCA1 gene sequencing' => %w[BRCA1],
              'BRCA2 gene MLPA' => %w[BRCA2],
              'BRCA2 gene sequencing' => %w[BRCA2]
            }.freeze

            BRCA_ANALYSIS_GENE_MAPPING_FS = {
              'BRCA1 and 2 gene sequencing' => %w[BRCA1 BRCA2],
              'Full Screen' => %w[BRCA1 BRCA2]
            }.freeze

            BRCA_ANALYSIS_GENE_MAPPING_TAR = {
              'BRCA cDNA analysis' => %w[BRCA1 BRCA2],
              'BRCA1 gene MLPA' => %w[BRCA1],
              'BRCA1 gene sequencing' => %w[BRCA1],
              'BRCA2 gene MLPA' => %w[BRCA2],
              'BRCA2 gene sequencing' => %w[BRCA2]
            }.freeze

            OVRN_CNCR_PNL_GENE_MAPPING = {
              'BRCA1  BRCA2 & TP53' => %w[BRCA1 BRCA2 TP53],
              'BRCA1  BRCA2 and PALB2' => %w[BRCA1 BRCA2 PALB2],
              'BRCA1  BRCA2 and TP53' => %w[BRCA1 BRCA2 TP53],
              'BRCA1  BRCA2 and TP53 - analysis only' => %w[BRCA1 BRCA2 TP53],
              'BRCA1 & BRCA2 only' => %w[BRCA1 BRCA2],
              'BRCA1 and BRCA2' => %w[BRCA1 BRCA2],
              'BRCA1 and BRCA2 - analysis only' => %w[BRCA1 BRCA2],
              'Extended HBOC panel' => %w[ATM BRCA1 BRCA2 BRIP1 CDH1 CHEK2 EPCAM MLH1 MSH2 MSH6
                                          PALB2 PTEN RAD51C RAD51D STK11 TP53 PMS2],
              'Extended HBOC panel - analysis only' => %w[ATM BRCA1 BRCA2 BRIP1 CDH1 CHEK2 EPCAM
                                                          MLH1 MSH2 MSH6 PALB2 PTEN RAD51C RAD51D
                                                          STK11 TP53 PMS2],
              'Full panel' => %w[ATM BRCA1 BRCA2 BRIP1 CDH1 CHEK2 EPCAM MLH1 MSH2 MSH6 PALB2 PTEN
                                 RAD51C RAD51D STK11 TP53 PMS2],
              'Full panel - analysis only' => %w[ATM BRCA1 BRCA2 BRIP1 CDH1 CHEK2 EPCAM MLH1 MSH2
                                                 MSH6 PALB2 PTEN RAD51C RAD51D STK11 TP53 PMS2],
              'Full panel - analysis only and TP53 MLPA' => %w[ATM BRCA1 BRCA2 BRIP1 CDH1 CHEK2
                                                               EPCAM MLH1 MSH2 MSH6 PALB2 PTEN
                                                               RAD51C RAD51D STK11 TP53 PMS2]
            }.freeze

            OVRN_COLO_PNL_GENE_MAPPING = {
              'Full panel' => %w[ATM BRCA1 BRCA2 BRIP1 CDH1 CHEK2 EPCAM MLH1 MSH2 MSH6 PALB2 PTEN
                                 RAD51C RAD51D STK11 TP53 PMS2]
            }.freeze

            R205_GENE_MAPPING_FS = {
              'R205.1 :: Unknown mutation(s) by Small panel' => %w[ATM BRCA1 BRCA2 CDH1 CHEK2
                                                                   PALB2 PTEN STK11 TP53],
              'R387.1 :: NGS Analysis only' => %w[ATM BRCA1 BRCA2 CDH1 CHEK2 PALB2 PTEN STK11 TP53],
              'R205.2 :: Unknown mutation(s) by MLPA or equivalent' => %w[ATM BRCA1 BRCA2 CDH1
                                                                          CHEK2 PALB2 PTEN
                                                                          STK11 TP53]
            }.freeze

            R205_GENE_MAPPING_TAR = {
              'R242.1 :: Predictive testing' => %w[ATM BRCA1 BRCA2 CDH1 CHEK2 PALB2 PTEN STK11
                                                   TP53],
              'R242.1 :: Predictive - MLPA' => %w[BRCA1 BRCA2 TP53]
            }.freeze

            R206_GENE_MAPPING = {
              'R206.1 :: Unknown mutation(s) by Small panel' => %w[ATM BRCA1 BRCA2 BRIP1 CDH1
                                                                   CHEK2 EPCAM MLH1 MSH2 MSH6
                                                                   PALB2 PTEN RAD51C RAD51D
                                                                   STK11 TP53 PMS2],
              'R206.2 :: Unknown mutation(s) by MLPA or equivalent' => %w[BRCA1 BRCA2 MLH1 MSH2
                                                                          TP53],
              'R387.1 :: Extended breastand ovarian cancer panel analysis only' => %w[ATM BRCA1
                                                                                      BRCA2 BRIP1
                                                                                      CDH1 CHEK2
                                                                                      EPCAM MLH1
                                                                                      MSH2 MSH6
                                                                                      PALB2 PTEN
                                                                                      RAD51C RAD51D
                                                                                      STK11 TP53
                                                                                      PMS2]
            }.freeze

            R207_GENE_MAPPING_FS = {
              'R207.1 :: Unknown mutation(s) by Small panel' => %w[BRCA1 BRCA2 BRIP1 EPCAM MLH1
                                                                   MSH2 MSH6 PALB2 RAD51C RAD51D
                                                                   PMS2],
              'R207.2 :: Unknown mutation(s) by MLPA or equivalent' => %w[BRCA1 BRCA2 MLH1 MSH2],
              'R387.1 :: NGS analysis only' => %w[BRCA1 BRCA2 BRIP1 EPCAM MLH1 MSH2
                                                  MSH6 PALB2 RAD51C RAD51D PMS2],
              'R207.1 :: NGS in Leeds' => %w[BRCA1 BRCA2 BRIP1 EPCAM MLH1 MSH2
                                             MSH6 PALB2 RAD51C RAD51D PMS2]
            }.freeze

            R207_GENE_MAPPING_TAR = {
              'R240.1 :: Diagnostic familial' => %w[BRCA1 BRCA2 BRIP1 EPCAM MLH1
                                                    MSH2 MSH6 PALB2 RAD51C RAD51D PMS2],
              'R242.1 :: Predictive testing' => %w[BRCA1 BRCA2 BRIP1 EPCAM MLH1
                                                   MSH2 MSH6 PALB2 RAD51C RAD51D PMS2]
            }.freeze

            R208_GENE_MAPPING_FS = {
              'R208.1 :: Unknown mutation(s) by Single gene sequencing' => %w[BRCA1 BRCA2 PALB2],
              'R208.2 :: Unknown mutation(s) by MLPA or equivalent' => %w[BRCA1 BRCA2],
              'R387.1 :: BRCA1 BRCA2 PALB2 analysis only' => %w[BRCA1 BRCA2 PALB2],
              'R208.1 :: NGS in Leeds' => %w[BRCA1 BRCA2 PALB2],
              'R208.1 :: PALB2 - NGS in Leeds - Analysis only' => %w[BRCA1 BRCA2 PALB2]
            }.freeze

            R208_GENE_MAPPING_TAR = {
              'R242.1 :: Predictive testing' => %w[BRCA1 BRCA2 PALB2],
              'R242.1 :: Predictive testing MLPA' => %w[BRCA1 BRCA2],
              'R240.1 :: Diagnostic familial' => %w[BRCA1 BRCA2 PALB2],
              'R240.1 :: Diagnostic Familial BRCA1 MLPA' => %w[BRCA1],
              'R370.1 :: Confirmation of research result' => %w[BRCA1 BRCA2 PALB2]
            }.freeze

            R240_GENE_MAPPING_TAR = {
              'R242.1 :: Familial diagnostic testing - ATM gene' => %w[ATM]
            }.freeze

            R242_GENE_MAPPING_TAR = {
              'R242.1 :: Predictive testing - ATM gene' => %w[ATM]
            }.freeze

            PASS_THROUGH_FIELDS = %w[consultantcode
                                     providercode
                                     collecteddate
                                     receiveddate
                                     authoriseddate
                                     servicereportidentifier
                                     genotype
                                     age
                                     karyotypingmethod
                                     genetictestscope].freeze

            NON_BRCA_SCOPE = ['Colorectal cancer panel',
                              'R209 :: Inherited colorectal cancer (with or without polyposis)',
                              'R210 :: Inherited MMR deficiency (Lynch syndrome)',
                              'R211 :: Inherited polyposis - germline test',
                              'R216 :: Li Fraumeni Syndrome',
                              'R217 :: Multiple endocrine neoplasia type 1',
                              'R218 :: Multiple endocrine neoplasia type 2',
                              'R220 :: Wilms tumour with suggestive features of predisposition',
                              'R224 :: Inherited renal cancer',
                              'R365 :: Fumarate hydratase-related tumour syndromes'].freeze

            BRCA_REGEX = /(?<brca>BRCA1|BRCA2|PALB2|ATM|CHEK2|TP53|MLH1|CDH1|
                          MSH2|MSH6|PMS2|STK11|PTEN|BRIP1|NBN|RAD51C|RAD51D)/ix.freeze

            # rubocop:disable Lint/MixedRegexpCaptureTypes
            CDNA_REGEX = /c\.\[?(?<cdna>
                                ([0-9]+[+>_-][0-9][+>_-][0-9]+[+>_-][0-9][ACGTdelinsup]+)|
                                ([0-9]+[+>_-][0-9][+>_-][0-9]+[+>_-][0-9]+[ACGTdelinsup]+)|
                                ([0-9]+[+>_-][0-9]+[ACGTdelinsup][+>_-][ACGTdelinsup])|
                                ([0-9]+[ACGTdelinsup]+[+>_-][ACGTdelinsup])|
                                ([0-9]+[+>_-][0-9]+[ACGTdelinsup]+)|
                                ([0-9]+[+>_-][0-9]+[+>_-][0-9]+[0-9]+[ACGTdelinsup]+)|
                                ([0-9]+[?+>_-]+[0-9]+[?+>_-]+[ACGTdelinsup]+)|
                                ([0-9]+[ACGTdelinsup]+)
                                )\]?/ix.freeze

            MLPA_FAIL_REGEX = /#{BRCA_REGEX}\s(?<mlpa>MLPA?\sfail)+/ix.freeze

            PROTEIN_REGEX = /p\.(\[\()?(?<impact>.([a-z]+[0-9]+[a-z]+([^[:alnum:]][0-9]+)?)|
                                   ([a-z]+[0-9]+[^[:alnum:]]))(\)\])?/ix.freeze

            EXON_VARIANT_REGEX = /(?<ex>(?<zygosity>het|homo)[a-z ]+)?
                                  (?<mutationtype>deletion|duplication|duplicated)\s?
                                  ([a-z 0-9]+ (exon|exons)\s
                                  (?<exons>[0-9]+([a-z -]+[0-9]+)?))|
                                  (?<ex>(?<zygosity>het|homo)[a-z ]+)?
                                  (?<ex>(?<nm>exon|exons)\s(?<exons>[0-9]+([a-z -]+[0-9]+)?))
                                  ([a-z ]+
                                  (?<mutationtype>deletion|duplication|duplicated))?/ix.freeze

            DEL_DUP_REGEX = /(?:\W*(del)(?:etion|[^\W])?)|(?:\W*(dup)(?:lication|[^\W])?)/i.freeze

            NORMAL_VAR_REGEX = %r{(?<not>no|not)[a-z /]+
                                  (?<det>detect|report|detet|mutation)+}ix.freeze
            # rubocop:enable Lint/MixedRegexpCaptureTypes
          end
        end
      end
    end
  end
end
