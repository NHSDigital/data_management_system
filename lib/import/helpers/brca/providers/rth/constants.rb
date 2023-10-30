module Import
  module Helpers
    module Brca
      module Providers
        module Rth
          module Constants
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
                                  TP53)/ix

            RECORD_EXEMPTIONS = ['c.[-835C>T]+[=]', 'Deletion of whole PTEN gene',
                                 'c.[-904_-883dup ]+[=]', 'whole gene deletion',
                                 'Deletion partial exon 11 and exons 12-15',
                                 'deletion BRCA1 exons 21-24', 'deletion BRCA1 exons 21-24',
                                 'deletion BRCA1 exons 1-17', 'whole gene duplication'].freeze

            PROTEIN_REGEX = /p\.\[?\(?(?<impact>.+)(?:\))|
                             p\.\[(?<impact>[a-z0-9*]+)\]|
                             p\.(?<impact>[a-z]+[0-9]+[a-z]+)/ix

            CDNA_REGEX = /c\.\[?(?<cdna>[0-9]+.+[a-z]+)\]?/i

            EXON_REGEX = /(?<variant>del|inv|dup).+ion\s(?<of>of\s)?
                          exon(?<s>s)?\s?(?<location>[0-9]+(?<moreexon>-[0-9]+)?)|
                          exon(?<s>s)?\s?(?<location>[0-9]+(?<moreexon>-[0-9]+)?)
                          \s(?<variant>del|inv|dup).+ion/ix

            GENOMICCHANGE_REGEX = /Chr(?<chromosome>\d+)\.hg
                                   (?<genome_build>\d+):g\.(?<effect>.+)/ix

            VAR_PATH_CLASS_MAP = {
              'c3' => 3,
              'c4' => 4,
              'c5' => 5,
              '10' => 'invalidvariantpathclass',
              'n/a' => 'invalidvariantpathclass'
            }.freeze
          end
        end
      end
    end
  end
end
