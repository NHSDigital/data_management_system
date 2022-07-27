module Import
  module Helpers
    module Brca
      module Providers
        module Rj1
          module Rj1Constants
            # CDNA_REGEX = /c\.(?<cdna>[^\s]+)/ix.freeze
            METHODS_MAP = [
              %i[ashkenazi_test? process_ashkenazi_test],
              %i[polish_test? process_polish_test],
              %i[targeted_test_first_option? process_targeted_test],
              %i[targeted_test_second_option? process_targeted_test],
              %i[targeted_test_third_option? process_targeted_test],
              %i[targeted_test_fourth_option? process_targeted_test],
              %i[full_screen_test_option1? process_fullscreen_test_option1],
              %i[full_screen_test_option2? process_fullscreen_test_option2],
              %i[full_screen_test_option3? process_fullscreen_test_option3]
            ].freeze

            # rubocop:disable Lint/MixedRegexpCaptureTypes
            CDNA_REGEX = /(\w+\s)?c\.\s?(?<cdna>[^\s]+)|(?<cdna>^[0-9].+)\s?\(M\)/i
            PROTEIN_REGEX = /p\.\(?(?<impact>[a-z]+[0-9]+[a-z]+)\)?/i
            EXON_REGEX = /(?<zygosity>het|hom)?\.?\s(?<deldup>del(etion)?|dup(lication)?)\.?[\s\w]+?
                          ex(on)?\s?(?<exons>[0-9]+(?<otherexon>-[0-9]+)?)|ex(on)?\s?
                          (?<exons>[0-9]+(?<otherexon>-[0-9]+)?)\s?(?<zygosity>het|hom)?\.?\s?
                          (?<deldup>del(etion)?|dup(lication)?)\.?|
                          (?<zygosity>het|hom)?\s?(?<deldup>del|dup)\s?ex(?<ons>ons)?\s?
                          (?<exons>[0-9]+(?<otherexon>-[0-9]+)?)|
                          (?<zygosity>het|hom)?\s?del\s
                          ex(on)?(?<exons>[0-9]+(?<otherexon>-[0-9]+)?)/ix

            MALFORMED_CDNA_REGEX = /(?<donotgrep>het|BRCA1|BRCA2)?\s?(?<cdna>[^\s]+)/i
            # rubocop:enable Lint/MixedRegexpCaptureTypes
            BRCA_GENES_REGEX = /(?<brca>BRCA1|
                                       BRCA2|
                                       ATM|
                                       P041|
                                       CHEK2|
                                       PALB2|
                                       MLH1|
                                       MSH2|
                                       MSH6|
                                       MUTYH|
                                       SMAD4|
                                       NF1|
                                       NF2|
                                       SMARCB1|
                                       LZTR1)/xi

            DEPRECATED_BRCA_NAMES_MAP = { 'BR1'    => 'BRCA1',
                                          'B1'     => 'BRCA1',
                                          'BRCA 1' => 'BRCA1',
                                          'BR2'    => 'BRCA2',
                                          'B2'     => 'BRCA2',
                                          'BRCA 2' => 'BRCA2' }.freeze

            DEPRECATED_BRCA_NAMES_REGEX = /B1|BR1|BRCA\s1|B2|BR2|BRCA\s2/i

            BRCA1_MUTATIONS = ['het c.68_69delAG (p.Glu23fs)', 'het c.5266dupC (p.Gln1756fs) (M)',
                               'Het c.68_69delAG p.(Glu23fs) (M)', 'c.302-1g>t (M)'].freeze
            BRCA2_MUTATIONS = ['c.5946delT (M)', 'c.5946delT (p.Ser1982fs) (M)',
                               'BRCA2 c.5946del p.(Ser1982fs)', 'Het c.1736T>G p.(Leu579Ter)',
                               '6275_6276delTT (M)', '4478_4481delAAAG (M)',
                               'c. 5130_5133delTGTA (M)'].freeze
          end
        end
      end
    end
  end
end
