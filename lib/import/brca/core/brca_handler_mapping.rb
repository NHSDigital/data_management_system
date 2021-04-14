# TODO: Needed?

module Import
  module Brca
    module Core
      # Provides the handler appropriate for the dataformat from each center
      class BrcaHandlerMapping
        HANDLER_MAPPING = {
          'RR8' => Import::Brca::Providers::Leeds::LeedsHandler,
          'RNZ' => Import::Brca::Providers::Salisbury::SalisburyHandler,
          'RVJ' => Import::Brca::Providers::Bristol::BristolHandler,
          'RTD' => Import::Brca::Providers::Newcastle::NewcastleHandler,
          'RX1' => Import::Brca::Providers::Nottingham::NottinghamHandler,
          'RCU' => Import::Brca::Providers::Sheffield::SheffieldHandler,
          'R0A' => Import::Brca::Providers::Manchester::ManchesterHandler,
          'RJ1' => Import::Brca::Providers::StThomas::StThomasHandler,
          # 'RQ3' => Import::Brca::Providers::Birmingham::BirminghamHandler,
          'RGT' => Import::Brca::Providers::Cambridge::CambridgeHandler,
          'RTH' => Import::Brca::Providers::Oxford::OxfordHandler,
          'RJ7' => Import::Brca::Providers::StGeorge::StGeorgeHandler,
          'RPY' => Import::Brca::Providers::RoyalMarsden::RoyalMarsdenHandler,
          'R1K' => Import::Brca::Providers::LondonKgc::LondonKgcHandler,
          'RQ3' => Import::Brca::Providers::Birmingham::BirminghamHandlerNewformat
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
