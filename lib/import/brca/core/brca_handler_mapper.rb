# TODO: Needed?
require 'providers/leeds/leeds_handler'
require 'providers/salisbury/salisbury_handler'
require 'providers/bristol/bristol_handler'
require 'providers/newcastle/newcastle_handler'
require 'providers/nottingham/nottingham_handler'
require 'providers/sheffield/sheffield_handler'
require 'providers/manchester/manchester_handler'
require 'providers/st_thomas/st_thomas_handler'
require 'providers/birmingham/birmingham_handler'
require 'providers/cambridge/cambridge_handler'
require 'providers/oxford/oxford_handler'
require 'providers/st_george/st_george_handler'
require 'providers/royal_marsden/royal_marsden_handler'
require 'providers/london_kgc/london_kgc_handler'
require 'import/central_logger'

module Import
  module Brca
    module Core
      # Provides the handler appropriate for the dataformat from each center
      class BRCAHandlerMapping
        HANDLER_MAPPING = {
          'RR8' => Import::Brca::Providers::Leeds::LeedsHandler,
          'RNZ' => Import::Brca::Providers::Salisbury::SalisburyHandler,
          'RVJ' => Import::Brca::Providers::Bristol::BristolHandler,
          'RTD' => Import::Brca::Providers::Newcastle::NewcastleHandler,
          'RX1' => Import::Brca::Providers::Nottingham::NottinghamHandler,
          'RCU' => Import::Brca::Providers::Sheffield::SheffieldHandler,
          'R0A' => Manchester::ManchesterHandler,
          'RJ1' => StThomas::StThomasHandler,
          'RQ3' => Import::Brca::Providers::Birmingham::BirminghamHandler,
          'RGT' => Import::Brca::Providers::Cambridge::CambridgeHandler,
          'RTH' => Import::Brca::Providers::Oxford::OxfordHandler,
          'RJ7' => StGeorge::StGeorgeHandler,
          'RPY' => RoyalMarsden::RoyalMarsdenHandler,
          'R1K' => Import::Brca::Providers::LondonKgc::LondonKgcHandler
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
