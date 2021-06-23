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
                     'TP53' => 79,
                     'MLH1' => 2744,
                     'MSH2' => 2804,
                     'MSH6' => 2808,
                     'PMS2' => 3394,
                     'PTEN' => 62,
                     'STK11' => 76,
                     'BRIP1' => 590,
                     'NBN' => 2912,
                     'RAD51C' => 3615,
                     'RAD51D' => 3616 }.freeze

        BRCA_REGEX = /(?<atm>ATM)|
                      (?<chek2>CHEK2)|
                      (?<palb2>PALB2)|
                      (?<brca1>BRCA1)|
                      (?<brca2>BRCA2)|
                      (?<tp53>TP53)|
                      (?<mlh1>MLH1)|
                      (?<msh2>MSH2)|
                      (?<msh6>MSH6)|
                      (?<pms2>PMS2)|
                      (?<stk>STK11)|
                      (?<pten>PTEN)|
                      (?<brip1>BRIP1)|
                      (?<nbn>NBN)|
                      (?<rad51c>RAD51C)|
                      (?<rad51d>RAD51D)/ix.freeze # Added by Francesco

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

        def add_gene(brca_input)
          case brca_input
          when Integer
            process_integer_imput(brca_input)
          when String
            process_string_imput(brca_input)
          else
            @logger.error "Bad input type given for BRCA extraction: #{brca_input}"
          end
        end

        def process_integer_imput(brca_input)
          if [7, 8, 79, 451, 865, 3186, 2744, 2804, 3394, 62, 76,
              590, 2912, 3615, 3616].include? brca_input
            @attribute_map['gene'] = brca_input
            @logger.debug "SUCCESSFUL gene parse for #{brca_input}"
          elsif (1..2).cover? brca_input
            @attribute_map['gene'] = brca_input + 6
          else
            @logger.error "Invalid gene reference given to addGene; given: #{brca_input}"
          end
        end

        def process_string_imput(brca_input)
          return if brca_input.empty?

          match_num = brca_input.strip.scan(BRCA_REGEX).size
          if match_num > 1
            @logger.debug "Too many genes given for BRCA cancers extraction: #{brca_input}"
          elsif match_num.zero?
            @logger.debug "No detected genes given for BRCA cancers extraction: #{brca_input}"
          else
            if brca_input.include? '/'
              @logger.debug 'WARNING: string provided for gene extraction contains a slash,'\
                            "possible multi-gene error: #{brca_input}"
            end
            case variable = BRCA_REGEX.match(brca_input.strip)
            when nil
              @logger.debug 'Null input for BRCA genes'
            else
              @attribute_map['gene'] = BRCA_MAP[variable&.to_s]
              @logger.debug "SUCCESSFUL gene parse for #{brca_input}"
            end
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
      end
    end
  end
end
