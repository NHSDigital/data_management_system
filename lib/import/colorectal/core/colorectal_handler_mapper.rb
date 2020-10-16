# TODO: Needed?
require 'providers/leeds/leeds_handler_colorectal'
require 'providers/salisbury/salisbury_handler_colorectal'
require 'providers/newcastle/newcastle_handler_colorectal'
require 'providers/nottingham/nottingham_handler_colorectal'
require 'providers/sheffield/sheffield_handler_colorectal'
require 'providers/cambridge/cambridge_handler_colorectal'
require 'providers/manchester/manchester_handler_colorectal'
require 'providers/london_kgc/london_kgc_handler_colorectal'
require 'providers/royal_marsden/royal_marsden_handler_colorectal'
require 'providers/london_gosh/london_gosh_handler_colorectal'
require 'import/central_logger'

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
          'RP4' => Import::Colorectal::Providers::LondonGosh::LondonGoshHandlerColorectal
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
