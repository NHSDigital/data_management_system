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
          'RTH' => Import::Colorectal::Providers::Oxford::OxfordHandlerColorectal,
          'REP' => Import::Colorectal::Providers::Liverpool::LiverpoolHandlerColorectal
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
