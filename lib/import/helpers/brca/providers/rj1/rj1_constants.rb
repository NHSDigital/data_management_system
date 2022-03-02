module Import
  module Helpers
    module Brca
      module Providers
        module Rj1
          module Rj1Constants

            # CDNA_REGEX = /c\.(?<cdna>[^\s]+)/ix.freeze
            METHODS_MAP = [
              [:ashkenazi_test?, :process_ashkenazi_test],
              [:polish_test?, :process_polish_test],
              [:targeted_test_first_option?, :process_targeted_test_first_option],
              [:targeted_test_second_option?, :process_targeted_test_first_option]
              ]
            
            
            CDNA_REGEX = /(\w+\s)?c\.\s?(?<cdna>[^\s]+)|(?<cdna>^[0-9].+)\s?\(M\)/i.freeze
            EXON_REGEX = /(?<zygosity>het|hom)\.?\s(?<deldup>del(etion)?|dup(lication)?)\.?[\s\w]+?
                          ex(on)?\s?(?<exons>[0-9]+(?<otherexon>-[0-9]+)?)|ex(on)?\s?
                          (?<exons>[0-9]+(?<otherexon>-[0-9]+)?)\s?(?<zygosity>het|hom)?\.?\s?
                          (?<deldup>del(etion)?|dup(lication)?)\.?/ix.freeze

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
            BRCA1_MUTATIONS = [ "het c.68_69delAG (p.Glu23fs)", "het c.5266dupC (p.Gln1756fs) (M)", 
                               "Het c.68_69delAG p.(Glu23fs) (M)", "c.302-1g>t (M)"]
            BRCA2_MUTATIONS = ["c.5946delT (M)", "c.5946delT (p.Ser1982fs) (M)",
                               "BRCA2 c.5946del p.(Ser1982fs)", "Het c.1736T>G p.(Leu579Ter)",
                               "6275_6276delTT (M)", "4478_4481delAAAG (M)", 
                               "c. 5130_5133delTGTA (M)" ]
          end
        end
      end
    end
  end
end
