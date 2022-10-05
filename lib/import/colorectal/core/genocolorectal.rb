require 'date'
require 'possibly'
module Import
  module Colorectal
    module Core
      # This class forms the core intermediary between raw records coming in, and formatted records
      # ready for database inseration. As field values are added, the inseration methods attempt
      # to convert the field values into the codes used by the schema
      # Roughly speaking, each Genotype
      # object would compare to a SequenceVariant level record, if all tests
      # (including negative ones) produced sequence variants
      # However, each genotype also contains all the information available about test
      # and result level fields, so that the storage processor can match and create the
      # appropriate tables
      class Genocolorectal < Import::Germline::Genotype
        #--------------------- Schema code mapping tables --------------------------

        COLORECTAL_MAP = { 'APC' => 358,
                           'BMPR1A' => 577,
                           'EPCAM' => 1432,
                           'TACSTD1' => 1432,
                           'MLH1' => 2744,
                           'MSH2' => 2804,
                           'MSH6' => 2808,
                           'MUTYH' => 2850,
                           'PMS2' => 3394,
                           'POLD1' => 3408,
                           'POLE' => 5000,
                           'PTEN' => 62,
                           'SMAD4' => 72,
                           'STK11' => 76,
                           'GREM1' => 1882,
                           'NTHL1' => 3108 }.freeze

        COLORECTAL_REGEX = /(?<apc>APC)|
                            (?<bmpr>BMPR1A)|
                            (?<epcam>EPCAM)|
                            (?<tacstd1>TACSTD1)|
                            (?<mlh1>MLH1)|
                            (?<msh2>MSH2)|
                            (?<msh6>MSH6)|
                            (?<mutyh>MUTYH)|
                            (?<pms2>PMS2)|
                            (?<pold>POLD1)|
                            (?<pole>POLE)|
                            (?<pten>PTEN)|
                            (?<smad>SMAD4)|
                            (?<stk>STK11)|
                            (?<grem>GREM1)|
                            (?<nthl>NTHL1)/ix # Added by Francesco

        # ------------------------ Interogators ------------------------------

        # this is present in Newcastle storage manager
        def full_screen?
          scope = @attribute_map['genetictestscope']
          return nil unless scope

          scope == 'Full screen Colorectal Lynch or MMR'
        end

        def add_gene_colorectal(colorectal_input)
          case colorectal_input
          when Integer
            if [1432, 358, 577, 2744, 2804, 2808, 2850, 3394,
                3408, 5000, 62, 72, 76, 1882, 3108].include? colorectal_input

              @attribute_map['gene'] = colorectal_input
              @logger.debug "SUCCESSFUL gene parse for #{colorectal_input}"
            else
              @logger.error "Invalid gene reference given to addGene; given: #{colorectal_input}"
            end

          when String
            return if colorectal_input.empty?

            match_num = colorectal_input.strip.scan(COLORECTAL_REGEX).size
            if match_num > 1
              @logger.debug 'Too many genes given for colorectal cancers extraction:' \
                            "#{colorectal_input}"
            elsif match_num.zero?
              @logger.debug 'No detected genes given for colorectal cancers extraction: ' \
                            "#{colorectal_input}"
            else
              if colorectal_input.include? '/'
                @logger.debug 'WARNING: string provided for gene extraction contains a slash,'\
                              "possible multi-gene error: #{colorectal_input}"
              end
              case variable = COLORECTAL_REGEX.match(colorectal_input.strip)
              when nil
                @logger.debug "Bad input string given for gene extraction: #{colorectal_input}"
              else
                @attribute_map['gene'] = COLORECTAL_MAP[variable&.to_s]
                @logger.debug "SUCCESSFUL gene parse for #{colorectal_input}"
              end
            end
          else
            @logger.error "Bad input type given for colorectal extraction: #{colorectal_input}"
          end
        end

        def dup_colo
          Import::Colorectal::Core::Genocolorectal.new(@raw_record, @attribute_map.dup)
        end

        def add_test_scope(scope)
          return if scope.blank?

          case scope
          when :full_screen
            @attribute_map['genetictestscope'] = 'Full screen Colorectal Lynch or MMR'
          when :targeted_mutation
            @attribute_map['genetictestscope'] = 'Targeted Colorectal Lynch or MMR'
          when :aj_screen
            @attribute_map['genetictestscope'] = 'AJ Colorectal Lynch or MMR'
          when :polish_screen
            @attribute_map['genetictestscope'] = 'Polish Colorectal Lynch or MMR'
          when :no_genetictestscope
            @attribute_map['genetictestscope'] = 'Unable to assign Colorectal Lynch'\
            ' or MMR genetictestscope'
          else
            @logger.warn "Bad key given to addTestScope: #{scope}"
          end
        end
      end
    end
  end
end
