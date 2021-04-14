require 'date'
require 'possibly'
module Import
  module Brca
    module Core
      # This class forms the core intermediary between raw records coming in, and formatted records
      # ready for database inseration. As field values are added, the inseration methods attempt
      # to convert the field values into the codes used by the schema. Roughly speaking, each
      # Genotype object would compare to a SequenceVariant level record, if all tests (including
      # negative ones)produced sequence variants.
      # However, each genotype also contains all the information available about test and result
      # level fields, so that the storage processor can match and create the appropriate tables
      class GenotypeBrca < Import::Genotype
        BRCA_MAP = { 'BRCA1' => 7,
                     'BRCA2' => 8,
                     'ATM' => 451,
                     'CHEK2' => 865,
                     'PALB2' => 3186,
                     'TP53' => 79
                    }.freeze

        BRCA_REGEX = /(?<atm>ATM)|
                      (?<chek2>CHEK2)|
                      (?<palb2>PALB2)|
                      (?<brca1>BRCA1)|
                      (?<brca2>BRCA2)|
                      (?<tp53>TP53)/ix .freeze # Added by Francesco

        def other_gene
          gene = @attribute_map['gene']
          return nil unless gene

          case gene
          when 8 then 7
          when 7 then 8
          else
            @logger.warn "Something very wrong, trying to get gene opposite of: #{gene}"
          end
        end

        # def add_gene(brca_input)
        #   case brca_input
        #   when nil
        #     @logger.error 'Null input for gene'
        #   when Integer
        #     gene_integer_input(brca_input)
        #   when String
        #     gene_string_input(brca_input)
        #   else
        #     @logger.error "Bad input type given for brca1/2 extraction: #{brca_input}"
        #   end
        # end

        # def gene_integer_input(brca_input) # edit so that doesn't guess BRCA genes from Colorectal Genes
        #   if (1..2).cover? brca_input
        #     # BRCA 1 and 2 map to gene codes 7 and 8
        #     @attribute_map['gene'] = brca_input + 6
        #   elsif (7..8).cover? brca_input
        #     @attribute_map['gene'] = brca_input
        #   else
        #     @logger.error 'Invalid gene reference given to addGene; ' \
        #     "needs 1 or 2, given: #{brca_input}"
        #   end
        # end
        #
        # def gene_string_input(brca_input)
        #   return if brca_input.empty?
        #
        #   match_num = brca_input.strip.scan(BRCA_REGEX).size
        #   if match_num > 1
        #     @logger.debug 'Bad input string (too many genes) given for brca1/2'\
        #     " extraction: #{brca_input}"
        #   elsif match_num.zero?
        #     @logger.debug 'Bad input string (no detected genes) given for brca1/2'\
        #     " extraction: #{brca_input}"
        #   else
        #     if brca_input.include? '/'
        #       @logger.debug 'WARNING: string provided for gene extraction contains a'\
        #       "slash, possible multi-gene error: #{brca_input}"
        #     end
        #
        #     gene_regex_input(brca_input)
        #   end
        # end

        def add_gene(brca_input)
          case brca_input
          when Integer
            if [7,8,79,451,865,3186].include? brca_input

              @attribute_map['gene'] = brca_input
              @logger.debug "SUCCESSFUL gene parse for #{brca_input}"
            elsif (1..2).cover? brca_input
              @attribute_map['gene'] = brca_input + 6
            else
              @logger.error "Invalid gene reference given to addGene; given: #{brca_input}"
            end

          when String
            return if brca_input.empty?

            match_num = brca_input.strip.scan(BRCA_REGEX).size
            if match_num > 1
              @logger.debug 'Too many genes given for BRCA cancers extraction:' \
                            "#{brca_input}"
            elsif match_num.zero?
              @logger.debug 'No detected genes given for BRCA cancers extraction: ' \
                            "#{brca_input}"
            else
              if brca_input.include? '/'
                @logger.debug 'WARNING: string provided for gene extraction contains a slash,'\
                              "possible multi-gene error: #{brca_input}"
              end
              case variable = BRCA_REGEX.match(brca_input.strip)
              when nil
                @logger.debug "Null input for BRCA genes"
              else
                @attribute_map['gene'] = BRCA_MAP[variable&.to_s]
                @logger.debug "SUCCESSFUL gene parse for #{brca_input}"
              end
            end
          else
            @logger.error "Bad input type given for BRCA extraction: #{brca_input}"
          end
        end






        def add_test_scope(scope)
          return if scope.blank?

          case scope
          when :full_screen
            @attribute_map['genetictestscope'] = 'Full screen BRCA1 and BRCA2'
          when :targeted_mutation
            @attribute_map['genetictestscope'] = 'Targeted BRCA mutation test'
          when :aj_screen
            @attribute_map['genetictestscope'] = 'AJ BRCA screen'
          when :polish_screen
            @attribute_map['genetictestscope'] = 'Polish BRCA screen'
          else
            @logger.warn "Bad key given to addTestScope: #{scope}"
          end
        end

        def dup
          Import::Brca::Core::GenotypeBrca.new(@raw_record, @attribute_map.dup)
        end

        # def gene_regex_input(brca_input)
        #   case BRCA_REGEX.match(brca_input.strip)
        #   when nil
        #     @logger.debug "Bad input string given for brca1/2 extraction: #{brca_input}"
        #   else
        #     add_gene($LAST_MATCH_INFO[1].to_i)
        #   end
        # end
      end
    end
  end
end
