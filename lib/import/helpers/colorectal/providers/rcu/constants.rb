module Import
  module Helpers
    module Colorectal
      module Providers
        module Rcu
          # Constants used by SheffieldColorectal
          module Constants
            TEST_TYPE_MAPPING_COLO = { 'diagnostic testing' => :diagnostic,
                                       'further sample for diagnostic testing' => :diagnostic,
                                       'confirmation of familial mutation' => :diagnostic,
                                       'confirmation of research result' => :diagnostic,
                                       'diagnostic testing for known mutation' => :diagnostic,
                                       'predictive testing' => :predictive,
                                       'family studies' => :predictive }.freeze

            PASS_THROUGH_FIELDS_COLO = %w[consultantcode
                                          providercode
                                          collecteddate
                                          receiveddate
                                          authoriseddate
                                          servicereportidentifier
                                          genotype
                                          age].freeze

            NON_CRC_GENTICTESCOPE = [
              'r208 :: inherited breast cancer and ovarian cancer',
              'r208 :: brca1 and brca2 testing at high familial risk',
              'r205 :: inherited breast cancer (without ovarian cancer) at very high familial risk',
              'brca1 and 2 gene analysis',
              'brca1 and 2 familial mutation',
              'men1',
              'breast & ovarian cancer panel',
              'r217 :: multiple endocrine neoplasia type 1',
              'r207 :: inherited ovarian cancer (without breast cancer)',
              'hlrcc / mcul',
              'wt1',
              'r365 :: fumarate hydratase-related tumour syndromes',
              'r217 :: multiple endocrine neoplasia type 1',
              'r224 :: inherited renal cancer',
              'r220 :: wilms tumour with features suggestive of predisposition - sdgs',
              'fumarate hydratase deficiency',
              'r216 :: li fraumeni syndrome',
              'r220 :: wilms tumour with features suggestive of predisposition',
              'men2',
              'r242 - predictive testing - hered cancers',
              'r195 :: proteinuric renal disease - inhouse',
              'r218.1 :: unknown mutation(s) by single gene sequencing',
              'r218 :: multiple endocrine neoplasia type 2',
              'r365 :: fumarate hydratase-related tumour syndromes - sdgs',
              'r240 - familial diagnostic testing - hered cancers',
              'r206 :: inherited breast cancer and ovarian cancer at high familial risk levels',
              'r216 :: li fraumeni syndrome - sdgs'
            ].freeze

            GENETICTESTSCOPE_METHOD_MAPPING = {
              'colorectal cancer panel' => :process_scope_colorectal_panel,
              'r209 :: inherited colorectal cancer '\
              '(with or without polyposis)' => :process_scope_r209,
              'r210 :: inherited mmr deficiency (lynch syndrome)' => :process_scope_r210,
              'r211 :: inherited polyposis - germline test' => :process_scope_r211,
              'fap' => :process_scope_fap,
              'fap familial mutation' => :process_scope_fap_familial,
              'hnpcc' => :process_scope_hnpcc,
              'myh' => :process_scope_myh,
              'breast ovarian & colorectal cancer panel' => :process_scope_colo_ovarian_panel,
              'r211 :: inherited polyposis and early onset colorectal cancer, germline testing'=> :process_scope_r211,
              'r414 :: apc associated polyposis'=> :process_scope_r414
            }.freeze

            COLO_PANEL_GENE_MAPPING_FS = {
              'APC & MUTYH' => %w[APC MUTYH],
              'APC and MUTYH' => %w[APC MUTYH],
              'Extended CRC panel' => %w[MLH1 MSH2 MSH6 PMS2 EPCAM APC
                                         MUTYH BMPR1A PTEN POLD1 POLE
                                         SMAD4 STK11],
              'Extended CRC panel - analysis only' => %w[MLH1 MSH2 MSH6 PMS2 EPCAM
                                                         APC MUTYH BMPR1A PTEN POLD1
                                                         POLE SMAD4 STK11],
              'Full panel' => %w[ATM BRCA1 BRCA2 BRIP1 CDH1 CHEK2 EPCAM MLH1 MSH2 MSH6 PALB2 PTEN RAD51C RAD51D STK11 TP53 PMS2],
              'MLH1  MSH2  MSH6  PMS1 & PMS2' => %w[MLH1 MSH2 MSH6 PMS1 PMS2],
              'MLH1  MSH2  MSH6 and PMS2' => %w[MLH1 MSH2 MSH6 PMS2],
              'MLH1  MSH2 and MSH6' => %w[MLH1 MSH2 MSH6],
              'MLH1 MSH2 & MSH6' => %w[MLH1 MSH2 MSH6],
              'MLH1 MSH2 and MSH6 - analysis only' => %w[MLH1 MSH2 MSH6],
              'MLH1 MSH2 MSH6 Analysis only' => %w[MLH1 MSH2 MSH6],
              'MLH1. MSH2  MSH6 and PMS2 - analysis only' => %w[MLH1 MSH2 MSH6 PMS2]
            }.freeze

            COLO_PANEL_GENE_MAPPING_TAR = {
              'PTEN familial mutation' => %w[PTEN],
              'STK11 familial mutation' => %w[STK11]
            }.freeze


            R414_PANEL_GENE_MAPPING_FS = {
              'R414.1 :: APC sequencing in Leeds' => %w[APC]
            }.freeze

            R209_PANEL_GENE_MAPPING_FS = {
              'R209.1 :: NGS - APC and MUTYH only' => %w[APC MUTYH],
              'R209.1 :: Small panel in Leeds' => %w[MLH1 MSH2 MSH6 PMS2 EPCAM APC MUTYH BMPR1A
                                                     PTEN POLD1 POLE SMAD4 STK11],
              'R209.1 :: Unknown mutation(s) by Small panel' => %w[MLH1 MSH2 MSH6 PMS2 EPCAM APC
                                                                   MUTYH BMPR1A PTEN POLD1 POLE
                                                                   SMAD4 STK11],
              'R209.2 :: Unknown mutation(s) by MLPA or equivalent' => %w[MLH1 MSH2 APC MUTYH],
              'R209.2 :: MLPA - FAP' => %w[APC MUTYH],
              'R387.1 :: NGS analysis only' => %w[]
            }.freeze

            R209_PANEL_GENE_MAPPING_TAR = {
              'R242.1 :: Predictive testing' => %w[MLH1 MSH2 MSH6 PMS2 EPCAM APC MUTYH
                                                   BMPR1A PTEN POLD1 POLE SMAD4 STK11]
            }.freeze

            R210_PANEL_GENE_MAPPING_FS = {
              'R210.2 :: Small panel in Leeds' => %w[MLH1 MSH2 MSH6 PMS2 EPCAM],
              'R210.2 :: Unknown mutation(s) by Small panel' => %w[MLH1 MSH2 MSH6 PMS2 EPCAM],
              'R210.5 :: Unknown mutation(s) by MLPA or equivalent' => %w[MLH1 MSH2 EPCAM],
              'R210.1 :: Unknown mutation(s) by Microsatellite instability'=> %w[MLH1 MSH2 MSH6 PMS2 EPCAM],
              'R210.2 :: Small panel in Leeds - Send DNA'=> %w[MLH1 MSH2 MSH6 PMS2 EPCAM]
            }.freeze

            R210_PANEL_GENE_MAPPING_TAR = {
              'R240.1 :: Diagnostic familial' => %w[MLH1 MSH2 MSH6 PMS2 EPCAM],
              'R242.1 :: Predictive MLPA' => %w[MLH1 MSH2 EPCAM],
              'R242.1 :: Predictive testing' => %w[MLH1 MSH2 MSH6 PMS2 EPCAM],
              'R242.1 :: Predictive testing - MLPA in Leeds - Send Blood'=> %w[MLH1 MSH2 MSH6 PMS2 EPCAM],
              'R242.1 :: Predictive testing - MLPA in Leeds - Send DNA'=> %w[MLH1 MSH2 MSH6 PMS2 EPCAM],
              'R242.1 :: Predictive testing - Seq in Leeds - Send Blood'=> %w[MLH1 MSH2 MSH6 PMS2 EPCAM],
              'R242.1 :: Predictive testing - Seq in Leeds - Send DNA'=> %w[MLH1 MSH2 MSH6 PMS2 EPCAM]
            }.freeze

            R210_PANEL_GENE_MAPPING_MOL = {
              'R296.1 :: RNA analysis for a variant' => %w[MLH1 MSH2 MSH6 PMS2 EPCAM],
              'R387.1 :: NGS - MMR deficiency analysis only' => %w[MLH1 MSH2 MSH6 PMS2 EPCAM]
            }.freeze

            R211_PANEL_GENE_MAPPING_FS = {
              'R211.1 :: Small Panel in Leeds' => %w[APC BMPR1A EPCAM MLH1 MSH2 MSH6 MUTYH NTHL1 PMS2 POLD1 POLE PTEN RNF43 SMAD4 STK11],
              'R211.1 :: Small panel in Leeds - send DNA sample'=> %w[APC BMPR1A EPCAM MLH1 MSH2 MSH6 MUTYH NTHL1 PMS2 POLD1 POLE PTEN RNF43 SMAD4 STK11],
              'R211.1 :: APC and MUTYH genes in Leeds' => %w[APC MUTYH],
              'R211.2 :: Unknown mutation(s) by MLPA or equivalent' => %w[APC MUTYH]
            }.freeze

            R211_PANEL_GENE_MAPPING_TAR = {
              'R240.1 :: Diagnostic familial' => %w[APC MUTYH],
              'R240.1 :: Diagnostic familial - Seq in Leeds - Send Blood'=> %w[APC BMPR1A EPCAM MLH1 MSH2 MSH6 MUTYH NTHL1 PMS2 POLD1 POLE PTEN RNF43 SMAD4 STK11],
              'R242.1 :: Predictive testing' => %w[APC BMPR1A EPCAM MLH1 MSH2 MSH6 MUTYH NTHL1 PMS2 POLD1 POLE PTEN RNF43 SMAD4 STK11],
              'R242.1 :: Predictive testing - Seq in Leeds - Send Blood' => %w[APC BMPR1A EPCAM MLH1 MSH2 MSH6 MUTYH NTHL1 PMS2 POLD1 POLE PTEN RNF43 SMAD4 STK11],
              'R242.1 :: Predictive testing - Seq in Leeds - Analysis only'=> %w[APC BMPR1A EPCAM MLH1 MSH2 MSH6 MUTYH NTHL1 PMS2 POLD1 POLE PTEN RNF43 SMAD4 STK11],
              'R242.1 :: Predictive testing - Seq in Leeds - Send DNA'=> %w[APC BMPR1A EPCAM MLH1 MSH2 MSH6 MUTYH NTHL1 PMS2 POLD1 POLE PTEN RNF43 SMAD4 STK11]
            }.freeze

            R211_PANEL_GENE_MAPPING_MOL = {
              'R387.1 ::  APC and MUTYH analysis only' => %w[APC MUTYH],
              'R244.1 :: Carrier testing' => %w[MUTYH]
            }.freeze

            FAP_PANEL_GENE_MAPPING_MOL = {
              'APC gene MLPA' => %w[APC],
              'APC gene sequencing' => %w[APC],
              'Default' => %w[APC]
            }.freeze

            FAP_FAM_PANEL_GENE_MAPPING_TAR = {
              'APC gene MLPA' => %w[APC],
              'APC gene sequencing' => %w[APC]
            }.freeze

            HNPCC_NON_GRMLINE = ['BRAF', 'MSI', 'MSI 1 PET and VB', 'MSI 2 PET and VB'].freeze

            HNPCC_PANEL_GENE_MAPPING_FS = {
              'MLH1 and MSH2' => %w[MLH1 MSH2]
            }.freeze

            HNPCC_PANEL_GENE_MAPPING_TAR = {
              'MLH1' => %w[MLH1],
              'MLH1 gene sequencing' => %w[MLH1],
              'MSH2' => %w[MSH2],
              'MSH2 gene sequencing' => %w[MSH2]
            }.freeze

            HNPCC_PANEL_GENE_MAPPING_MOL = {
              'Default' => %w[MLH1 MSH2 MSH6],
              'MLPA for MLH1 and MSH2' => %w[MLH1 MSH2],
              'MSH6' => %w[MSH6]
            }.freeze

            OVRN_COLO_PNL_GENE_MAPPING = {
              'Full panel' => %w[ATM BRCA1 BRCA2 BRIP1 CDH1 CHEK2 EPCAM MLH1 MSH2 MSH6 PALB2
                                 PTEN RAD51C RAD51D STK11 TP53 PMS2]
            }.freeze

            MOLECULAR_SCOPE_MAPPING = {
              'carrier testing' => :no_genetictestscope,
              'confirmation of familial mutation' => :targeted_mutation,
              'diagnostic testing' => :full_screen,
              'diagnostic testing for known mutation' => :targeted_mutation,
              'family studies' => :targeted_mutation,
              'predictive testing' => :targeted_mutation
            }.freeze

            # rubocop:disable Lint/MixedRegexpCaptureTypes
            NORMAL_VAR_REGEX = %r{(?<not>no|not)[a-z /]+
                                  (?<det>detected|reported|deteected|deteceted|present)+}ix.freeze

            CDNA_REGEX = /c\.\[?(?<cdna>
                                ([0-9]+[+>_-][0-9][+>_-][0-9]+[+>_-][0-9][ACGTdelinsup]+)|
                                ([0-9]+[+>_-][0-9][+>_-][0-9]+[+>_-][0-9]+[ACGTdelinsup]+)|
                                ([0-9 ?+>_-]+[ACGTdelinsup][?+>_-][ACGTdelinsup])|
                                ([0-9]+[ACGTdelinsup]+[+>_-][ACGTdelinsup])|
                                ([0-9]+[+>_-][0-9]+[ACGTdelinsup]+)|
                                ([0-9]+[+>_-][0-9]+[+>_-][0-9]+[0-9]+[ACGTdelinsup]+)|
                                ([0-9 ?+>_-]+[ACGTdelinsup]+)|
                                ([0-9]+[ACGTdelinsup]+)
                                )\]?/ix.freeze

            EXON_VARIANT_REGEX = /(?<ex>(?<zygosity>het|homo)[a-z ]+)?
                                  (?<mutationtype>deletion|duplication|duplicated)\s?
                                  ([a-z 0-9]+ (exon|exons)\s
                                  (?<exons>[0-9]+([a-z -]+[0-9]+)?))|
                                  (?<ex>(?<nm>ex|exon|exons)
                                  (?<exons>([a-z 0-9-]+)?)
                                  (?<mutationtype>deletion|duplication|duplicated)(-)?
                                  (?<zygosity>het|homo)?)|
                                  (?<ex>(?<zygosity>het|homo)[a-z ]+)?
                                  (?<ex>(?<nm>exon|exons)\s(?<exons>[0-9]+([a-z -]+[0-9]+)?))
                                  ([a-z ]+
                                  (?<mutationtype>deletion|duplication|duplicated))?/ix.freeze

            PROTEIN_REGEX = /p\.[\[=+ \](]*(?<impact>
                            ([a-z 0-9]+([^[:alnum:]][0-9]+)?)|
                            ([a-z]+[0-9]+[^[:alnum:]])
                            )[)\]]?/ix.freeze

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
                                                  NTHL1)/xi.freeze # Added by
            NULL_TARGETED_TEST_REGEX = /(?<colorectal>APC|BMPR1A|EPCAM|
                                      MLH1|MSH2|MSH6|MUTYH|PMS2|POLD1|
                                      POLE|PTEN|SMAD4|STK11):
                                      \sFamilial\spathogenic\smutation\snot\sdetected/ix.freeze
            # rubocop:enable Lint/MixedRegexpCaptureTypes
          end
        end
      end
    end
  end
end
