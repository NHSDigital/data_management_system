module Import
  module Helpers
    module Colorectal
      module Providers
        module R0a
          # Constants used by ManchesterHandlerColorectal
          module R0aConstants
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
                                                  STK11)/xi . freeze

            MOLTEST_MAP = {
              'HNPCC (hMSH6) MUTATION SCREENING REPORT'              => 'MSH6',
              'HNPCC (MSH6) MUTATION SCREENING REPORT'               => 'MSH6',
              'HNPCC CONFIRMATORY TESTING REPORT'                    => %w[MLH1 MSH2 MSH6],
              'HNPCC MSH2 c.942+3A>T MUTATION TESTING REPORT'        => 'MSH2',
              'HNPCC MUTATION SCREENING REPORT'                      => %w[MLH1 MSH2],
              'HNPCC PREDICTIVE REPORT'                              => %w[MLH1 MSH2 MSH6],
              'HNPCC PREDICTIVE TESTING REPORT'                      => %w[MLH1 MSH2 MSH6],
              'LYNCH SYNDROME (@gene) - PREDICTIVE TESTING REPORT'   => %w[MLH1 MSH2 MSH6],
              'LYNCH SYNDROME (hMSH6) MUTATION SCREENING REPORT'     => 'MSH6',
              'LYNCH SYNDROME (MLH1) - PREDICTIVE TESTING REPORT'    => %w[MLH1 MSH2 MSH6],
              'LYNCH SYNDROME (MLH1/MSH2) MUTATION SCREENING REPORT' => %w[MLH1 MSH2],
              'LYNCH SYNDROME (MSH2) - PREDICTIVE TESTING REPORT'    => 'MSH2',
              'LYNCH SYNDROME (MSH6) - PREDICTIVE TESTING REPORT'    => 'MSH6',
              'LYNCH SYNDROME (MSH6) MUTATION SCREENING REPORT'      => 'MSH6',
              'LYNCH SYNDROME CONFIRMATORY TESTING REPORT'           => %w[MLH1 MSH2 MSH6],
              'LYNCH SYNDROME GENE SCREENING REPORT'                 => %w[MLH1 MSH2 MSH6],
              'LYNCH SYNDROME MUTATION SCREENING REPORT'             => %w[MLH1 MSH2 MSH6],
              'LYNCH SYNDROME SCREENING REPORT'                      => %w[MLH1 MSH2 MSH6],
              'MLH1/MSH2/MSH6 GENE SCREENING REPORT'                 => %w[MLH1 MSH2 MSH6],
              'MLH1/MSH2/MSH6 GENETIC TESTING REPORT'                => %w[MLH1 MSH2 MSH6],
              'MSH6 PREDICTIVE TESTING REPORT'                       => 'MSH6',
              'RARE DISEASE SERVICE - PREDICTIVE TESTING REPORT'     => %w[MLH1 MSH2 MSH6],
              'VARIANT TESTING REPORT'                               => %w[MLH1 MSH2 MSH6]
            }.freeze

            MOLTEST_MAP_DOSAGE = {
              'HNPCC DOSAGE ANALYSIS REPORT'                               => %w[MLH1 MSH2 MSH6],
              'MSH6  DOSAGE ANALYSIS REPORT'                               => 'MSH6',
              'LYNCH SYNDROME DOSAGE ANALYSIS REPORT'                      => %w[MLH1 MSH2 MSH6],
              'LYNCH SYNDROME DOSAGE ANALYSIS - PREDICTIVE TESTING REPORT' => %w[MLH1 MSH2 MSH6],
              'LYNCH SYNDROME (MSH6) DOSAGE ANALYSIS REPORT'               => 'MSH6'
            }.freeze

            CDNA_REGEX = /c\.(?<cdna>[0-9]+[a-z]+\>[a-z]+)|
                         c\.(?<cdna>[0-9]+.[0-9]+[a-z]+>[a-z]+)|
                         c\.(?<cdna>[0-9]+_[0-9]+[a-z]+)|
                         c\.(?<cdna>[0-9]+[a-z]+)|
                         c\.(?<cdna>.+\s[a-z]>[a-z])|
                         c\.(?<cdna>[0-9]+_[0-9]+\+[0-9]+[a-z]+)/ix .freeze

            PROT_REGEX = /p\.(\()?(?<impact>[a-z]+[0-9]+[a-z]+)(\))?/i .freeze
            EXON_REGEX = /(?<insdeldup>ins|del|dup)/i .freeze
            EXON_LOCATION_REGEX = /ex(?<exon>[\d]+)(.[\d]+)?(\sto\s)?(ex(?<exon2>[\d]+))?/i .freeze
          end
        end
      end
    end
  end
end
