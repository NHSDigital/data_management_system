require 'test_helper'

class BrcaHandlerMappingTest < ActiveSupport::TestCase
  test 'intialize' do
    assert get_handler('RQ3')
  end

  HANDLER_MAPPING = {
    'RR8' => 'Leeds',
    'RNZ' => 'Salisbury',
    'RVJ' => 'Bristol',
    'RTD' => 'Newcastle',
    'RX1' => 'Nottingham',
    'RCU' => 'Sheffield',
    'R0A' => 'Manchester',
    'RJ1' => 'StThomas',
    'RQ3' => 'Birmingham',
    'RGT' => 'Cambridge',
    'RTH' => 'Oxford',
    'RJ7' => 'StGeorge',
    'RPY' => 'RoyalMarsden'
  }.freeze

  def get_handler(provider_code)
    handler = HANDLER_MAPPING[provider_code]
    raise("No handler registered for code:#{provider_code}") unless handler

    handler
  end
end
