# TODO: Needed?
# require 'import/colorectal/providers/leeds/leeds_handler_colorectal'
# require 'import/colorectal/providers/salisbury/salisbury_handler_colorectal'
# require 'import/colorectal/providers/newcastle/newcastle_handler_colorectal'
# require 'import/colorectal/providers/nottingham/nottingham_handler_colorectal'
# require 'import/colorectal/providers/sheffield/sheffield_handler_colorectal'
# require 'import/colorectal/providers/cambridge/cambridge_handler_colorectal'
# require 'import/colorectal/providers/manchester/manchester_handler_colorectal'
# require 'import/colorectal/providers/london_kgc/london_kgc_handler_colorectal'
# require 'import/colorectal/providers/royal_marsden/royal_marsden_handler_colorectal'
# require 'import/colorectal/providers/london_gosh/london_gosh_handler_colorectal'
# require 'import/colorectal/providers/birmingham/birmingham_handler_colorectal'
# require 'import/colorectal/providers/oxford/oxford_handler_colorectal'

module Import
  module Colorectal
    module Core
      # Provides the handler appropriate for the dataformat from each center
      class ColorectalHandlerMapping
        HANDLER_MAPPING = {
          'RR8' => Import::Colorectal::Providers::Leeds::LeedsHandlerColorectal,
          'RNZ' => Import::Colorectal::Providers::Salisbury::SalisburyHandlerColorectal,
          'RTD' => Import::Colorectal::Providers::Newcastle::NewcastleHandlerColorectal,
          'RX1' => Import::Colorectal::Providers::Nottingham::NottinghamHandlerColorectal,
          'RCU' => Import::Colorectal::Providers::Sheffield::SheffieldHandlerColorectal,
          'RGT' => Import::Colorectal::Providers::Cambridge::CambridgeHandlerColorectal,
          'R1K' => Import::Colorectal::Providers::LondonKgc::LondonKgcHandlerColorectal,
          'R0A' => Import::Colorectal::Providers::Manchester::ManchesterHandlerColorectal,
          'RPY' => Import::Colorectal::Providers::RoyalMarsden::RoyalMarsdenHandlerColorectal,
          'RP4' => Import::Colorectal::Providers::LondonGosh::LondonGoshHandlerColorectal,
          'RQ3' => Import::Colorectal::Providers::Birmingham::BirminghamHandlerColorectal,
          'RTH' => Import::Colorectal::Providers::Oxford::OxfordHandlerColorectal
        }.freeze

        def self.get_handler(provider_code)
          handler = HANDLER_MAPPING[provider_code]
          Log.get_logger.debug "Selecting handler: #{handler} for code: #{provider_code}" if handler
          raise("No handler registered for code:#{provider_code}") unless handler

          handler
        end
      end
    end
  end
end
