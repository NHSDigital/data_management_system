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
            ORG_CODE_MAP = {
              'kennedy galton' => 'R1K01',
              'kennedy-galton centre' => 'R1K01',
              'northwick park' => 'R1K01',
              'northwick park hospital' => 'R1K01',
              'bristol royal' => 'RA701',
              "st michael's" => 'RA707',
              "st michael's, bristol" => 'RA707',
              "st michael's/bristol" => 'RA707',
              'st michaels' => 'RA707',
              'st michaels, bristol' => 'RA707',
              'st. michaels' => 'RA707',
              "st michael's hospital" => 'RA707',
              'bristol childrens' => 'RA723',
              'royal sick children, bristol' => 'RA723',
              'royal united hospital bath' => 'RD130',
              'royal united,bath' => 'RD130',
              'royal united' => 'RD130',
              'royal united hospital' => 'RD130',
              'cornwall' => 'REF12',
              'addenbrookes' => 'RGT01',
              "addenbrooke's hospital" => 'RGT01',
              'cambridge' => 'RGT01',
              'musgrove park' => 'RH5A8',
              'musgrove park hospital' => 'RH5A8',
              'somerset' => 'RH5A8',
              'taunton' => 'RH5A8',
              'taunton and somerset' => 'RH5A8',
              'exeter hospital' => 'RH802',
              'heavitree' => 'RH802',
              'heavitree hospital' => 'RH802',
              'peninsula clinical genetics' => 'RH802',
              'peninsula clinical genetics service' => 'RH802',
              'royal devon & exeter' => 'RH802',
              'royal devon and exeter' => 'RH802',
              'royal devon & exeter hospital' => 'RH802',
              'royal devon and exeter hospital' => 'RH802',
              'peninsula clinical genetics service truro' => 'RH855',
              '7th floor, borough wing' => 'RJ121',
              'clinical genetics guys' => 'RJ121',
              'gu genetics centre' => 'RJ121',
              'guy clinical genetics centre' => 'RJ121',
              "guy's clinical genetics centre" => 'RJ121',
              'guys genet' => 'RJ121',
              'guys genetics centre' => 'RJ121',
              'guys genetics clinic' => 'RJ121',
              'guys hospital' => 'RJ121',
              'guys/genetics centre' => 'RJ121',
              "guys/guy's genetics centre" => 'RJ121',
              "guy's hospital" => 'RJ121',
              "guy's and st thomas'" => 'RJ121',
              'guys clinical genetics' => 'RJ121',
              'regional molecular genetics laboratory' => 'RJ121',
              'st georges' => 'RJ701',
              "st george's" => 'RJ701',
              "st george's healthcare nhs trust" => 'RJ701',
              "st george's hospital medical school" => 'RJ701',
              'salisbury' => 'RNZ02',
              'salisbury/guys' => 'RNZ02',
              'wessex clinical genetics service' => 'RNZ02',
              'camelia botnar labs/ioch' => 'RP401',
              'great ormond street (clinical genetics)' => 'RP401',
              'great ormond street hospital' => 'RP401',
              'cancer genetics, royal marsden hospital' => 'RPY02',
              'institute of cancer research' => 'RPY02',
              'marsden' => 'RPY02',
              'royal marsden' => 'RPY02',
              'royal marsdon' => 'RPY02',
              'royal marsden hospital' => 'RPY02',
              'the royal marsden' => 'RPY02',
              'gloucester' => 'RTE03',
              'gloucester royal' => 'RTE03',
              'gloucestershire' => 'RTE03',
              'gloucestershire royal' => 'RTE03',
              'gloucester royal hospital' => 'RTE03',
              'gloucestershire royal hospital' => 'RTE03',
              'southmead bristol' => 'RVJ01',
              'southmead, bristol' => 'RVJ01',
              'southmead hospital' => 'RVJ01'
            }.freeze
          end
        end
      end
    end
  end
end
