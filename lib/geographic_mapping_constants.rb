# Constants for mapping 9-character geographies to old short codes
module GeographicMappingConstants
  GOR_MAPPING = {
    'E12000001' => 'A', # North East
    'E12000002' => 'B', # North West
    'E12000003' => 'D', # Yorkshire and The Humber
    'E12000004' => 'E', # East Midlands
    'E12000005' => 'F', # West Midlands
    'E12000006' => 'G', # East of England
    'E12000007' => 'H', # London
    'E12000008' => 'J', # South East
    'E12000009' => 'K', # South West
    'W99999999' => 'W', # Wales
    'N99999999' => 'Y', # Northern Ireland
    # Extra codes not in the old system all map to nil:
    'S99999999' => nil, # Scotland
    'M99999999' => nil, # Isle of Man
    'L99999999' => nil  # Channel Island
  }.freeze
end
