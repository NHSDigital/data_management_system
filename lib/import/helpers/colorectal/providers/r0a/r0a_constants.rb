module Import
  module Helpers
    module Colorectal
      module Providers
        module R0a
          # Constants used by ManchesterHandlerColorectal -- 21017388
          module R0aConstants
            DO_NOT_IMPORT = [
              'BRCA1 PREDICTIVE TESTING REPORT',
              'BRCA1/BRCA2 GENE SCREENING REPORT',
              'BRCA1/BRCA2 GENETIC TESTING REPORT',
              'BRCA2 PREDICTIVE TESTING REPORT',
              'COLORECTAL CANCER GENE SCREENING ON ARCHIVE PATHOLOGY TISSUE',
              'COLORECTAL CANCER MUTATION ANALYSIS ON ARCHIVE PATHOLOGY TISSUE',
              'MICROSATELLITE INSTABILITY (MSI) TESTING REPORT',
              'MLH1 PROMOTER HYPERMETHYLATION AND BRAF MUTATION TESTING REPORT',
              'SOMATIC MISMATCH REPAIR GENE ANALYSIS ON PATHOLOGY TISSUE',
              'SOMATIC MISMATCH REPAIR GENE MUTATION ANALYSIS ON PATHOLOGY TISSUE',
              'BRCA1/BRCA2/PALB2 GENETIC TESTING REPORT',
              'EGFR MUTATION TESTING REPORT',
              'GENOMICS LABORATORY REPORT:COPY PANEL / R CODE FROM LIST*',
              'BRCA1 VARIANT CONFIRMATION REPORT',
              'COLORECTAL CANCER SOMATIC GENE PANEL TESTING REPORT',
              'BRCA2 VARIANT CONFIRMATION REPORT',
              'BRCA1/BRCA2/PALB2 GENETIC TESTING REPORT',
              'INHERITED CARDIAC CONDITIONS - @PREDICTIVEORVARIANT TESTING REPORT',
              'METABOLIC DISORDERS - @PREDICTIVEORVARIANT TESTING REPORT',
              'TUMOUR BRCA1/BRCA2 MUTATION ANALYSIS'
            ].freeze
            PASS_THROUGH_FIELDS_COLO = %w[age consultantcode servicereportidentifier providercode
                                          authoriseddate requesteddate practitionercode
                                          genomicchange specimentype].freeze

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
                                                  CDH1)/xi

            MSH6_DOSAGE_MTYPE = ['LYNCH SYNDROME (MSH6) DOSAGE ANALYSIS REPORT',
                                 'MSH6  DOSAGE ANALYSIS REPORT'].freeze

            MOLTEST_GENE_MAP = {
              'HNPCC (HMSH6) MUTATION SCREENING REPORT' => ['MSH6'],
              'HNPCC (MSH6) MUTATION SCREENING REPORT' => ['MSH6'],
              'HNPCC CONFIRMATORY TESTING REPORT' => %w[MLH1 MSH2 MSH6 EPCAM],
              'HNPCC DOSAGE ANALYSIS REPORT' => %w[MLH1 MSH2 MSH6 EPCAM],
              'HNPCC MSH2 C.942+3A>T MUTATION TESTING REPORT' => ['MSH2'],
              'HNPCC MUTATION SCREENING REPORT' => %w[MLH1 MSH2 EPCAM],
              'HNPCC PREDICTIVE REPORT' => %w[MLH1 MSH2 MSH6 EPCAM],
              'HNPCC PREDICTIVE TESTING REPORT' => %w[MLH1 MSH2 MSH6 EPCAM],
              'LYNCH SYNDROME (@GENE) - PREDICTIVE TESTING REPORT' => %w[MLH1 MSH2 MSH6 EPCAM],
              'LYNCH SYNDROME (HMSH6) MUTATION SCREENING REPORT' => ['MSH6'],
              'LYNCH SYNDROME (MLH1) - PREDICTIVE TESTING REPORT' => %w[MLH1 MSH2 MSH6 EPCAM],
              'LYNCH SYNDROME (MLH1/MSH2) MUTATION SCREENING REPORT' => %w[MLH1 MSH2 EPCAM],
              'LYNCH SYNDROME (MSH2) - PREDICTIVE TESTING REPORT' => %w[MSH2 EPCAM],
              'LYNCH SYNDROME (MSH6) - PREDICTIVE TESTING REPORT' => ['MSH6'],
              'LYNCH SYNDROME (MSH6) MUTATION SCREENING REPORT' => ['MSH6'],
              'LYNCH SYNDROME CONFIRMATORY TESTING REPORT' => %w[MLH1 MSH2 MSH6 EPCAM],
              'LYNCH SYNDROME DOSAGE ANALYSIS - PREDICTIVE TESTING REPORT' => %w[MLH1 MSH2 MSH6
                                                                                 EPCAM],
              'LYNCH SYNDROME DOSAGE ANALYSIS REPORT' => %w[MLH1 MSH2 MSH6 EPCAM],
              'LYNCH SYNDROME GENE SCREENING REPORT' => %w[MLH1 MSH2 MSH6 EPCAM],
              'LYNCH SYNDROME MUTATION SCREENING REPORT' => %w[MLH1 MSH2 MSH6 EPCAM],
              'LYNCH SYNDROME (MSH6) DOSAGE ANALYSIS REPORT' => ['MSH6'],
              'LYNCH SYNDROME SCREENING REPORT' => %w[MLH1 MSH2 MSH6 EPCAM],
              'MLH1/MSH2/MSH6 GENE SCREENING REPORT' => %w[MLH1 MSH2 MSH6 EPCAM],
              'MLH1/MSH2/MSH6 GENETIC TESTING REPORT' => %w[MLH1 MSH2 MSH6 EPCAM],
              'MSH6 DOSAGE ANALYSIS REPORT' => ['MSH6'],
              'MSH6  DOSAGE ANALYSIS REPORT' => ['MSH6'],
              'MSH6 PREDICTIVE TESTING REPORT' => ['MSH6'],
              'RARE DISEASE SERVICE - PREDICTIVE TESTING REPORT' => %w[MLH1 MSH2 MSH6 EPCAM],
              'VARIANT TESTING REPORT' => %w[MLH1 MSH2 MSH6 EPCAM APC
                                             MUTYH CDH1],
              '@GENE PREDICTIVE TESTING REPORT' => %w[MLH1 MSH2 MSH6 EPCAM APC
                                                      MUTYH CDH1],
              'APC/MUTYH GENE SCREENING REPORT' => %w[APC MUTYH],
              'APC/MUTYH SCREENING REPORT' => %w[APC MUTYH],
              'FAMILIAL ADENOMATOUS POLYPOSIS COLI MUTATION CONFIRMATION REPORT' => %w[APC MUTYH],
              'FAMILIAL ADENOMATOUS POLYPOSIS COLI PREDICTIVE TESTING REPORT' => %w[APC MUTYH],
              'GENETIC TESTING REPORT- VARIANT UPDATE' => %w[MLH1 MSH2 MSH6 EPCAM APC MUTYH CDH1],
              "GENOMICS LABORATORY REPORT:\r\nCOPY PANEL / R CODE FROM LIST" => %w[
                MLH1 MSH2 MSH6EPCAM APC MUTYH CDH1
              ],
              "GENOMICS LABORATORY REPORT:\r\nCOPY PANEL / R CODE FROM LIST – " \
              'DELETE REVISION NUMBER' => %w[
                MLH1 MSH2 MSH6 EPCAM APC MUTYH CDH1
              ],
              'INHERITED CANCER PANEL GENETIC TESTING REPORT' => %w[MLH1 MSH2 MSH6 EPCAM APC MUTYH
                                                                    CDH1],
              "INHERITED CANCER PANEL GENETIC TESTING REPORT \r\nR208 INHERITED BREAST & OVARIAN " \
              'CANCER SUBPANEL / R207 INHERITED OVARIAN CANCER SUBPANEL (DELETE AS ' \
              'APPROPRIATE)' => %w[MLH1 MSH2 MSH6 EPCAM APC MUTYH CDH1],
              "INHERITED CANCER PANEL GENETIC TESTING REPORT\r\n@SUBPANEL SUBPANEL" => %w[
                MLH1 MSH2 MSH6 EPCAM APC MUTYH CDH1
              ],
              "INHERITED CANCER PANEL GENETIC TESTING REPORT\r\n@SUBPANEL SUBPANEL " \
              '(@GENENUMBER GENES)' => %w[
                MLH1 MSH2 MSH6 EPCAM APC MUTYH CDH1
              ],
              "INHERITED CANCER PANEL GENETIC TESTING REPORT\r\nINHERITED BREAST & " \
              'OVARIAN CANCER SUBPANEL' => %w[
                MLH1 MSH2 MSH6 EPCAM APC MUTYH CDH1
              ]
            }.freeze
            # rubocop:disable Layout/LineLength, Lint/MixedRegexpCaptureTypes
            SCREEN_GENTIC_TESTING_REGEX = %r{screen|MLH1/MSH2/MSH6\sGENETIC\sTESTING\sREPORT}i
            GENOMICS_LAB_REPORT = %r{GENOMICS\sLABORATORY\sREPORT:[\n\r\s]+COPY\sPANEL\s/\sR\sCODE\sFROM\sLIST.*}i
            DOSAGE_HNPCC_GENTIC_TESTING_REGEX = /dosage|HNPCC\sMSH2\sc\.942\+3A>T\sMUTATION\sTESTING\sREPORT|GENETIC\sTESTING\sREPORT-\sVariant\sUpdate/i

            INHERIT_GENETIC_REPORT = /INHERITED\sCANCER\sPANEL\sGENETIC\sTESTING\sREPORT.*/i
            NORMAL_STATUS = /Normal|No\spathogenic\svariant|wild|No\sevidence\sof|No\sshift/ix

            FAIL_STATUS = /Obscures|primer|Fail|obstructs|mutation\snot\scovered|Not\svisible\sin\sF/ix

            CDNA_REGEX = /c\.(?<cdna>[\w+>*\-\[]+)?[\w\s.]?/ix

            PROT_REGEX = /p\.(\()?(?<impact>[a-z]+[0-9]+[a-z]+)(\))?/i

            EXON_REGEX = /(?<insdeldup>ins|del|dup|copies)/i
            EXON_LOCATION_REGEX = /(?<nm>(exon|ex))+\s?(?<exon>\d+)?\s?(-|to)?\s?(?<exon2>\d+)?\s?(?<mutationtype>ins|del|dup)?/i
            # rubocop:enable Layout/LineLength, Lint/MixedRegexpCaptureTypes
          end
        end
      end
    end
  end
end
