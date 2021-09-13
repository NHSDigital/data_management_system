module Import
  module Helpers
    module Brca
      module Providers
        module R0a
          module R0aConstants
            PASS_THROUGH_FIELDS_COLO = %w[age consultantcode servicereportidentifier providercode
                                          authoriseddate requesteddate practitionercode
                                          genomicchange specimentype].freeze

            BRCA_GENES_REGEX = /(?<brca>BRCA1|
                                       BR1|
                                       B1|
                                       P002|
                                       P002B|
                                       P087|
                                       BRCA2|
                                       BR2|
                                       B2|
                                       P045|
                                       P077|
                                       ATM|
                                       P041|
                                       CHEK2|
                                       P190|
                                       PALB2|
                                       MLH1|
                                       MSH2|
                                       MSH6|
                                       MUTYH|
                                       SMAD4|
                                       NF1|
                                       NF2|
                                       SMARCB1|
                                       LZTR1)/xi.freeze

            DO_NOT_IMPORT = ['CYSTIC FIBROSIS GENETIC ANALYSIS REPORT',
                             '**ANY TEXT** ANALYSIS REPORT',
                             'APC/MUTYH MUTATION SCREENING REPORT,',
                             'Familial Adenomatous Polyposis Coli Confirmatory Testing Report',
                             'FAMILIAL ADENOMATOUS POLYPOSIS COLI PREDICTIVE TESTING REPORT',
                             'FRAGILE X SYNDROME GENETIC ANALYSIS REPORT',
                             'HNPCC (MSH6) MUTATION SCREENING REPORT',
                             'HNPCC CONFIRMATORY TESTING REPORT',
                             'HNPCC MUTATION SCREENING REPORT',
                             'HNPCC PREDICTIVE REPORT',
                             'HNPCC PREDICTIVE TESTING REPORT',
                             'LYNCH SYNDROME (@gene) - PREDICTIVE TESTING REPORT',
                             'LYNCH SYNDROME (hMSH6) MUTATION SCREENING REPORT',
                             'LYNCH SYNDROME (MLH1) - PREDICTIVE TESTING REPORT',
                             'LYNCH SYNDROME (MLH1/MSH2) MUTATION SCREENING REPORT',
                             'LYNCH SYNDROME (MSH2) - PREDICTIVE TESTING REPORT',
                             'LYNCH SYNDROME (MSH6) DOSAGE ANALYSIS REPORT',
                             'LYNCH SYNDROME (MSH6) MUTATION SCREENING REPORT',
                             'LYNCH SYNDROME CONFIRMATORY TESTING REPORT',
                             'LYNCH SYNDROME GENE SCREENING REPORT',
                             'LYNCH SYNDROME MUTATION SCREENING REPORT',
                             'METABOLIC VARIANT TESTING REPORT: @gene',
                             'MLH1/MSH2/MSH6 GENETIC TESTING REPORT',
                             'MSH6 DOSAGE ANALYSIS REPORT',
                             'MUTYH ASSOCIATED POLYPOSIS PREDICTIVE TESTING REPORT',
                             'RARE DISEASE SERVICE - MUTATION CONFIRMATION REPORT',
                             'RARE DISEASE SERVICE - PREDICTIVE TESTING REPORT',
                             'RETINAL DYSTROPHY MUTATION ANALYSIS REPORT',
                             'RETINOBLASTOMA MUTATION SCREENING REPORT',
                             'RETINOBLASTOMA LINKAGE REPORT',
                             'SEGMENTAL OVERGROWTH SYNDROME SCREENING REPORT',
                             'SOMATIC CANCER NGS PANEL TESTING REPORT',
                             'TUMOUR BRCA1/BRCA2 MUTATION ANALYSIS',
                             'ZYGOSITY TESTING REPORT',
                             'BRCA 1 Unclassified Variant Loss of Heterozygosity Studies from Archive Material'].freeze

            CDNA_REGEX = /c\.(?<cdna>[0-9]+[a-z]+>[a-z]+)|
                         c\.(?<cdna>[0-9]+-[0-9]+[A-Z]+>[A-Z]+)|
                         c\.(?<cdna>[0-9]+.[0-9]+[a-z]+>[a-z]+)|
                         c\.(?<cdna>[0-9]+_[0-9]+[a-z]+)|
                         c\.(?<cdna>[0-9]+[a-z]+)|
                         c\.(?<cdna>.+\s[a-z]>[a-z])|
                         c\.(?<cdna>[0-9]+_[0-9]+\+[0-9]+[a-z]+)|
                         c\.(?<cdna>[0-9]+-[0-9]+_[0-9]+[a-z]+)|
                         c\.(?<cdna>[0-9]+\+[0-9]+_[0-9]+\+[0-9]+[a-z]+)|
                         c\.(?<cdna>-[0-9]+[a-z]+>[a-z]+)|
                         c\.(?<cdna>[0-9]+-[0-9]+_[0-9]+-[0-9]+[a-z]+)/ix.freeze

            PROT_REGEX = /p\.(\()?(?<impact>[a-z]+[0-9]+[a-z]+)(\))?/i.freeze
            EXON_REGEX = /(?<insdeldup>ins|del|dup)/i.freeze
            EXON_LOCATION_REGEX = /ex(?<exon>\d+)(.\d+)?(\sto\s)?(ex(?<exon2>\d+))?/i.freeze
            NORMAL_REGEX = /normal|wild type|No pathogenic variant identified|No evidence/i.freeze
          end
        end
      end
    end
  end
end
